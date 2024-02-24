{ config, pkgs, lib, ... }:
let
    user = "guest";
    password = "guest";
    hostname = "rpi";
    hardware = fetchTarball {
      url = "https://github.com/NixOS/nixos-hardware/archive/c9c1a5294e4ec378882351af1a3462862c61cb96.tar.gz";
      sha256 = "166dqx7xgrn0906y5yz5a5l66q52wql1nh6086y4pli7s69wvf1s";
    };
    #raw_gadget = pkgs.callPackage /mnt/raw-gadget/a.nix {};
in {
    imports = ["${hardware}/raspberry-pi/4"];

    #boot.extraModulePackages = [ raw_gadget ];
    nix.settings.sandbox = "relaxed";

    documentation.enable = false;

  environment.interactiveShellInit = ''
    export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
    export HISTSIZE=100000                   # big big history
    export HISTFILESIZE=100000               # big big history
    shopt -s histappend                      # append to history, don't overwrite it

    # Save and reload the history after each command finishes
    export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
  '';

    hardware = {
        raspberry-pi."4".dwc2 = {
            enable = true;
        };
    };

    nix.extraOptions = ''
    experimental-features = nix-command flakes repl-flake
    extra-platforms = aarch64-linux arm-linux armv7l-linux
    '';

    fileSystems = {
        "/" = {
            device = "/dev/disk/by-label/NIXOS_SD";
            fsType = "ext4";
            options = [ "noatime" ];
        };
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
#    boot.kernel.sysctl."net.ipv6.conf.vlan50.disable_ipv6" = true;
#    boot.kernel.sysctl."net.ipv6.conf.vlan51.disable_ipv6" = true;
    networking = {
        enableIPv6 = false;
        hostName = hostname;
        domain = "cypis.ovh";
        dhcpcd.enable = false;

#        vlans = {
#            vlan50 = { id=50; interface="eth0"; };
#            vlan51 = { id=51; interface="eth0"; };
#        };
#        interfaces.vlan50.ipv4.addresses = [{ address="192.168.50.100"; prefixLength=24; }];
#        interfaces.vlan51.ipv4.addresses = [{ address="192.168.51.100"; prefixLength=24; }];
        interfaces.eth0.ipv4.addresses = [{ address="192.168.100.100"; prefixLength=24; }];
        defaultGateway = "192.168.100.1";
#        defaultGateway = "192.168.50.1";
        nameservers = ["1.1.1.1" "8.8.8.8"];
#        nat.enable = true;
        firewall.enable = false;

#        nftables = {
#            enable = true;
#            ruleset = ''
#table ip filter {
#    chain FORWARD {
#        type filter hook forward priority 0; policy accept;
#        iifname "vlan50" counter
#        iifname "vlan51" counter
#        iifname "vlan51" oifname "vlan50" counter accept
#        iifname "vlan50" oifname "vlan51" ct state established,related counter accept
#    }
#    #chain OUTPUT {
#    #    type filter hook output priority 0; policy accept;
#    #    ip saddr 192.168.50.100 tcp flags & (rst) == rst counter drop
#    #}
#}
#table ip nat {
#    chain POSTROUTING {
#        type nat hook postrouting priority 100; policy accept;
#        counter
#        oifname "vlan50" counter masquerade
#    }
#}
#            '';
#        };
    };

    environment.systemPackages = with pkgs; [ vim ];
    services.openssh.enable = true;

    users = {
        mutableUsers = false;
        users."${user}" = {
            isNormalUser = true;
            password = password;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAheF8/M/8H3DFcLHZ1hCu5QKvFasZQWuMuveLisscavtOktUX6iST7AUW4vRQPlY3ykyglPSnYZYf5jaZC/csIKT45gy4qm7ZkKWpxZv4VnHfChxgmM+NBtyBQjkR3ksnptwcW6EVoXiRzgtamJEsYcf79jn4OxzZwqoPt7OfTc0TCnULRoMsFzk8Sd1H1RoePxwpzsDnY2S5xgUKh8x+Dmm/5L1jZRHvcbx6ioDXR8H542A5SZ73mvPl5zq+AN7GQVejTcE2t3v45IASEhHb1N153DJ1D5i3EF/GUmSlLpu6kK9E9Ng4mrF9rE9kY9px0X92KGDad/mFBCVMA7CXBQ=="
            ];
        };
        users."root" = {
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS2ZTOKORFFLxheNZsLNfZavXUiK8478eGn/pqsGE17 main@cypis.ovh"
                "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNDWLFGbN4a3j0T6y0/LFlFvgTyjZvJ92t74ePnh1AZVBOAjlJZU3bsEvwhmmRJ1TFomHqenpcEn3V5j3o40RBo= psondej@secretive.MacBook-Pro-(patryk).local"
            ];
        };
    };

    # Enable GPU acceleration
    # hardware.raspberry-pi."4".fkms-3d.enable = true;

    # services.xserver = {
    #   enable = true;
    #   displayManager.lightdm.enable = true;
    #   desktopManager.xfce.enable = true;
    # };

    #systemd.services.btattach = {
    #  before = [ "bluetooth.service" ];
    #  after = [ "dev-ttyAMA0.device" ];
    #  wantedBy = [ "multi-user.target" ];
    #  serviceConfig = {
    #    ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
    #  };
    #};

    # boot.kernelPackages = pkgs.linuxPackages_rpi4;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    virtualisation.docker = {
        enable = true;
        extraOptions  = "--iptables=False";
    };
    hardware.bluetooth.enable = true;

    security.rtkit.enable = true;
    services.pipewire = {
    enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;
    };
    boot.kernel.sysctl."kernel.hostname" = "${config.networking.hostName}.${config.networking.domain}";

    #boot.kernelPatches = [
    # {
    #    name = "fix-rawgadget";
    #    patch = ./raw-gadget.patch;
    # }
   #];

   #boot.crashDump.enable = true;
}