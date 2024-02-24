#!/usr/bin/env python3

import json
import os
import random
import string
import subprocess
import sys
import typing
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any, List, Union, Dict

from deploykit import DeployGroup, DeployHost
from invoke import task

ROOT = Path(__file__).parent.resolve()
os.chdir(ROOT)


# Deploy to all hosts in parallel
def deploy_nixos(hosts: List[DeployHost]) -> None:
    g = DeployGroup(hosts)

    def deploy(h: DeployHost) -> None:
        if "darwin" in h.host:
            # don't use sudo for darwin-rebuild
            command = "darwin-rebuild"
        else:
            command = "sudo nixos-rebuild"

        user_ssh = (h.user+'@') if h.user else ''
        res = h.run_local(
            ["nix", "flake", "archive", "--to", f"ssh://{user_ssh}{h.host}", "--json"],
            stdout=subprocess.PIPE,
            extra_env={
                'SHELL': '/bin/sh',
            }
        )
        data = json.loads(res.stdout)
        path = data["path"]

        hostname = h.host
        h.run(
            f"{command} switch --option accept-flake-config true --flake {path}#{hostname}"
        )

    g.run_function(deploy)


# @task
# def sotp(c: Any, acct: str) -> None:
#     """
#     Get TOTP token from sops
#     """
#     c.run(f"nix develop .#sotp -c sotp {acct}")


@task
def update_sops_files(c: Any) -> None:
    """
    Update all sops yaml. eg: inv update-sops-files
    """
    with open(f"{ROOT}/.sops.yaml", "w") as f:
        print("# AUTOMATICALLY GENERATED WITH:", file=f)
        print("# $ inv update-sops-files", file=f)

    c.run(f"nix eval --json -f {ROOT}/sops.yaml.nix | yq e -P - >> {ROOT}/.sops.yaml")
    c.run(
        f"""
find {ROOT}/hosts \
        -type f \
        -path '*/secrets/*' \
        -print0 | \
        xargs -0 -n1 sops updatekeys --yes || true
"""
    )


def get_hosts(hosts: str) -> List[DeployHost]:
    if hosts == "":
        res = subprocess.run(
            ["nix", "flake", "show", "--json", "--all-systems"],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        )
        data = json.loads(res.stdout)
        systems = data["nixosConfigurations"]
        return [DeployHost(f"{n}") for n in systems]

    # if "darwin" in hosts:
    #     return [
    #         DeployHost(f"{h}.nix-community.org", user="hetzner")
    #         for h in hosts.split(",")
    #     ]
    def get_host(v: str):
        if '@' in v:
            return DeployHost(host=v.split('@')[1], user=v.split('@')[0])
        return DeployHost(host=f'{v}')

    return [get_host(h) for h in hosts.split(",")]


@task
def deploy(c: Any, hosts: str = "") -> None:
    """
    Deploy to all servers. Use inv deploy --hosts root@build01 to deploy to a single server
    """
    deploy_nixos(get_hosts(hosts))


@task
def add_server(c: Any, hostname: str) -> None:
    """
    Generate new server keys and configurations. eg: inv add-server --hostname test.pl
    """
    print(f"Adding {hostname}")

    keys = json.loads(open(f"{ROOT}/pubkeys.json", "r").read())
    if keys["machines"].get(hostname, None):
        print("Configuration already exists")
        exit(-1)

    print("Adding key into pubkeys.json..")
    keys["machines"][hostname] = ""
    with open(f"{ROOT}/pubkeys.json", "w") as f:
        json.dump(keys, f, indent=2)

    print("Updating sops files")
    update_sops_files(c)

    print("Generating SSH keys")
    agekey = generate_ssh_keys(hostname)

    print("Adding key into pubkeys.json..")
    keys["machines"][hostname] = agekey
    with open(f"{ROOT}/pubkeys.json", "w") as f:
        json.dump(keys, f, indent=2)

    print("Updating sops files")
    update_sops_files(c)

    print("Generating Password")
    generate_root_password(hostname)

    print(f"Writing example hosts/{hostname}/configuration.nix")
    generate_example_configuration(hostname)

    print("Adding files into git")
    c.run(
        "git add "
        + f"{ROOT}/pubkeys.json "
        + f"{ROOT}/.sops.yaml "
        + f"{ROOT}/hosts/{hostname}"
    )


def generate_example_configuration(hostname: str) -> None:
    example_host_config = f"""
{{ inputs, pkgs, lib, config, ... }}:
{{
  imports = [
    # ./hardware-configuration.nix # auto generate by command: inv ssh-hardware --hostname root@1.1.1.1
    # ./networking.nix  # auto generate by command: inv ssh-networking --hostname root@1.1.1.1
    inputs.self.nixosModules.common
    inputs.self.nixosModules.disko
  ];

  system.stateVersion = "23.11";  # Don't change after deploy! Read docs.
}}"""
    file = Path(f"{ROOT}/hosts/{hostname}/configuration.nix")
    if not file.exists():
        file.open('wt').write(example_host_config)
    else:
        print(' Skipped.')


def generate_ssh_keys(hostname: str) -> str:
    agekey = ''
    for keytype in ['ed25519', 'rsa']:
        priv, pub = generate_private_key(keytype)
        if keytype == 'ed25519':
            agekey = get_pubkey_to_agekey(pub)

        set_sops_key(hostname, f'ssh_host_{keytype}_key', priv)
        set_sops_key(hostname, f'ssh_host_{keytype}_key.pub', pub)
    return agekey


def generate_private_key(keytype: str) -> typing.Tuple[str, str]:
    with TemporaryDirectory() as tmpdir:
        key = f"{tmpdir}/priv_key"
        if keytype == 'ed25519':
            subprocess.run(
                ["ssh-keygen", "-t", "ed25519", "-f", f"{key}", "-C", "", "-q", "-N", ""],
                check=True,
            )
        elif keytype == 'rsa':
            subprocess.run(
                ["ssh-keygen", "-t", "rsa", "-b", "4096", "-f", f"{key}", "-C", "", "-q", "-N", ""],
                check=True,
            )

        priv = open(key, 'rt').read()
        pub = open(key + ".pub", 'rt').read()
        return priv, pub


def get_public_key(privkey: str) -> str:
    with TemporaryDirectory() as tmpdir:
        keyfile = Path(tmpdir) / "priv_key"
        keyfile.open('wt').write(privkey)
        keyfile.chmod(0o600)

        # todo: usunac komentarze
        key = subprocess.run(
            ["ssh-keygen", "-y", "-f", f"{keyfile}"],
            stdout=subprocess.PIPE,
            text=True,
            check=True,
        )
        return key.stdout.strip()


def get_pubkey_to_agekey(pubkey: str) -> str:
    key = subprocess.run(
        ["ssh-to-age"],
        input=pubkey,
        stdout=subprocess.PIPE,
        check=True,
        text=True,
    )
    return key.stdout.strip()


def set_sops_key(hostname: str, key: str, value: str) -> None:
    sopsk = Path(f"{ROOT}/hosts/{hostname}/secrets/secrets.yaml")

    if not sopsk.exists():
        sopsk.parent.mkdir(0o755, parents=True, exist_ok=True)

        sopsk.open('wt').write(key + ': ')
        subprocess.run(
            [
                "sops",
                "--encrypt",
                "--in-place",
                f"{sopsk}",
            ],
            check=True,
        )

    subprocess.run(
        [
            "sops",
            "--set",
            f'["{key}"] ' + json.dumps(value),
            f"{sopsk}",
        ],
        check=True,
    )


def get_sops_all(hostname: str) -> typing.Dict[str, str]:
    ret = subprocess.run(
        [
            "sops",
            "--output-type=json",
            "--decrypt",
            f"{ROOT}/hosts/{hostname}/secrets/secrets.yaml",
        ],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )
    return json.loads(ret.stdout.strip())


def get_sops_key(hostname: str, key: str) -> str:
    ret = subprocess.run(
        [
            "sops",
            "--extract",
            f'["{key}"]',
            "--decrypt",
            f"{ROOT}/hosts/{hostname}/secrets/secrets.yaml",
        ],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )
    return ret.stdout.strip()


def generate_root_password(hostname: str) -> None:
    size = 14
    chars = string.ascii_letters + string.digits
    passwd = "".join(random.choice(chars) for x in range(size))
    passwd_hash = subprocess.check_output([
            # na osx tylko to dziala: docker run -it --rm alpine mkpasswd
            "docker",
            "run",
            "-it",
            "--rm",
            "alpine",

            # linux: mkpasswd -m sha-512 -S SALT -R 5000 PASSWORD
            "mkpasswd",
            "-m",
            "sha-512",
            "-s",
            passwd,
        ],
        # input=passwd,
        text=True,
    ).strip()
    set_sops_key(hostname, 'root-password', passwd)
    set_sops_key(hostname, 'root-password-hash', passwd_hash)


def decrypt_host_keys(hostname: str, tmpdir: Path) -> None:
    tmpdir = tmpdir / "etc" / "ssh"
    tmpdir.mkdir(mode=0o755, parents=True, exist_ok=True)

    sops_all = get_sops_all(hostname)
    for keyname in [
        "ssh_host_rsa_key",
        "ssh_host_rsa_key.pub",
        "ssh_host_ed25519_key",
        "ssh_host_ed25519_key.pub",
    ]:
        file = (tmpdir / keyname)
        value = sops_all[keyname]

        file.open('wt').write(value)
        if keyname.endswith(".pub"):
            file.chmod(0o644)
        else:
            file.chmod(0o600)


@task
def ssh_install_nixos(c: Any, machine: str, hostname: str) -> None:
    """
    format disks and install nixos, i.e.: inv ssh-install-nixos --machine adelaide --hostname root@adelaide.dse.in.tum.de
    """
    ask = input(f"Are you sure you want to install .#{machine} on {hostname}? [y/N] ")
    if ask != "y":
        return

    with TemporaryDirectory() as tmpdir:
        decrypt_host_keys(machine, Path(tmpdir))

        flags = [
            "--debug",
            "--option", "accept-flake-config", "true",
            # "--kexec", "https://github.com/.../nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz",
            "--no-reboot",
        ]

        flagsstr = ' '.join(flags)
        c.run(
            f"SHELL=/bin/sh nix run nixpkgs#nixos-anywhere -- {hostname} --extra-files {tmpdir} --flake '.#{machine}' {flagsstr}",
            echo=True,
        )


@task
def build_local(c: Any, hosts: str = "") -> None:
    """
    Build all servers. Use inv build-local --hosts build01 to build a single server
    """
    g = DeployGroup(get_hosts(hosts))

    def build_local(h: DeployHost) -> None:
        hostname = h.host
        h.run_local(
            # [
            #     "nixos-rebuild",
            #     "build",
            #     "--option", "accept-flake-config", "true",
            #     "--flake", f".#{hostname}",
            # ]
            # [
            #     "nixos-rebuild",
            #     "build",
            #     "--option", "accept-flake-config", "true",
            #     "--flake", f".#{hostname}",
            #     "--target-host", f"{hostname}",
            # ]
            [
                "nix", "build",
                f".#nixosConfigurations.\"{hostname}\".config.system.build.toplevel"
            ]
        )
        h.run_local([
            "nix", "copy",
            "--to", f"ssh://root@{hostname}?remote-store=local?root=/",
            "./result",
        ], extra_env={
            'SHELL': '/bin/sh',
        })

    g.run_function(build_local)


def wait_for_port(host: str, port: int, shutdown: bool = False) -> None:
    import socket
    import time

    while True:
        try:
            with socket.create_connection((host, port), timeout=1):
                if shutdown:
                    time.sleep(1)
                    sys.stdout.write(".")
                    sys.stdout.flush()
                else:
                    break
        except OSError:
            if shutdown:
                break
            else:
                time.sleep(0.01)
                sys.stdout.write(".")
                sys.stdout.flush()


@task
def reboot(c: Any, hosts: str = "") -> None:
    """
    Reboot hosts. example usage: inv reboot --hosts build01,build02
    """
    for h in get_hosts(hosts):
        h.run("sudo reboot &")

        print(f"Wait for {h.host} to shutdown", end="")
        sys.stdout.flush()
        port = h.port or 22
        wait_for_port(h.host, port, shutdown=True)
        print("")

        print(f"Wait for {h.host} to start", end="")
        sys.stdout.flush()
        wait_for_port(h.host, port)
        print("")


@task
def cleanup_gcroots(c: Any, hosts: str = "") -> None:
    g = DeployGroup(get_hosts(hosts))
    g.run("sudo find /nix/var/nix/gcroots/auto -type s -delete")
    g.run("sudo systemctl restart nix-gc")


def filter_interfaces(network: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    output = []
    for net in network:
        if net.get("link_type") == "loopback":
            continue
        if not net.get("address"):
            # We need a mac address to match devices reliable
            continue
        addr_info = []
        has_dynamic_address = False
        for addr in net.get("addr_info", []):
            # no link-local ipv4/ipv6
            if addr.get("scope") == "link":
                continue
            # do not explicitly configure addresses from dhcp or router advertisement
            if addr.get("dynamic", False):
                has_dynamic_address = True
                continue
            else:
                addr_info.append(addr)
        if addr_info != [] or has_dynamic_address:
            net["addr_info"] = addr_info
            output.append(net)

    return output


def filter_routes(routes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    filtered = []
    for route in routes:
        # Filter out routes set by addresses with subnets, dhcp and router advertisement
        if route.get("protocol") in ["dhcp", "kernel", "ra"]:
            continue
        filtered.append(route)

    return filtered


def get_network_config(interfaces: List[Dict[str, Any]], routes: List[Dict[str, Any]]) -> str:
    def route_section_tmp(gateway2, destination2):
        return f"""      {{
        routeConfig = {{
          {f'Gateway = "{gateway2}";' if gateway2 else ''}
          {f'Destination = "{destination2}";' if destination2 else ''}
        }};
      }}"""

    output = ''
    for interface in interfaces:
        addresses = [
            f"      \"{addr['local']}/{addr['prefixlen']}\""
            for addr in interface.get("addr_info", [])
        ]
        dhcp_option = ''
        if not addresses:
            dhcp_option = '    networkConfig.DHCP = "yes";\n'
            dhcp_option += '    networkConfig.IPv6AcceptRA = true;'

        route_sections = []
        for route in routes:
            if route.get("dev", "nodev") != interface.get("ifname", "noif"):
                continue

            gateway = route.get("gateway")
            route_dst = None
            if route.get("dst") != "default":
                # can be skipped for default routes
                route_dst = route['dst']

            # we may ignore on-link default routes here, but I don't see how
            # they would be useful for internet connectivity anyway
            route_sections.append(route_section_tmp(gateway, route_dst))

        newline = "\n"
        unit = f"""  systemd.network.networks."10-{interface["ifname"]}" = {{
    matchConfig.MACAddress = "{interface["address"]}";
{dhcp_option}
    address = [
{newline.join(addresses)}
    ];
    routes = [
{newline.join(route_sections)}
    ];
    linkConfig.RequiredForOnline = "routable";
  }};
"""
        output += unit
    return output


def generate_networking(h: DeployHost):
    # TODO: download ./ip.AppImage
    v4_routes = json.loads(h.run("ip -4 --json route", stdout=subprocess.PIPE).stdout)
    v6_routes = json.loads(h.run("ip -6 --json route", stdout=subprocess.PIPE).stdout)
    addresses = json.loads(h.run("ip --json addr", stdout=subprocess.PIPE).stdout)

    boot_device = None
    raw_disk = h.run("ls -al /dev/ | grep 'disk'", stdout=subprocess.PIPE).stdout
    for device in ['vda', 'sda']:
        if device in raw_disk:
            boot_device = '/dev/' + device

    if not boot_device:
        raise ValueError('boot_device is unknown')

    relevant_interfaces = filter_interfaces(addresses)
    relevant_routes = filter_routes(v4_routes) + filter_routes(v6_routes)

    network_cfg = get_network_config(relevant_interfaces, relevant_routes)

    tmp = f"""{{ pkgs, lib, config, ... }}:
let
  fqdn = builtins.baseNameOf ./.;
in {{
  nixCommunity.fqdn = fqdn;
  nixCommunity.disko.device = "{boot_device}";

  networking.useNetworkd = false;
  networking.useDHCP = false;
  systemd.network.enable = true;
{network_cfg}
}}"""
    return tmp


@task
def ssh_hardware(c: Any, hostname: str) -> None:
    """
    eg: inv ssh-hardware --hostname root@test.pl
    """
    for h in get_hosts(hostname):
        file = Path(f"{ROOT}/hosts/{h.host}/hardware-configuration.nix")
        if not file.exists():
            config = ''
            raise NotImplementedError('todo')
            # wget https://github.com/.../nixos-install-tools.AppImage
            # nixos-generate-config..AppImage --no-filesystems --root /tmp
            file.open('wt').write(config)
        else:
            print(' Skipped.')


@task
def ssh_networking(c: Any, hostname: str) -> None:
    """
    eg: inv ssh-networking --hostname root@test.pl
    """
    for h in get_hosts(hostname):
        file = Path(f"{ROOT}/hosts/{h.host}/networking.nix")
        if not file.exists():
            config = generate_networking(h)
            file.open('wt').write(config)
        else:
            print(' Skipped.')
