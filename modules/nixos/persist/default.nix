{ inputs, lib, config, ... }:
{
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp

    mkdir -p /btrfs_tmp/persist/system/etc/nixos
    mkdir -p /btrfs_tmp/persist/system/var/log
    mkdir -p /btrfs_tmp/persist/system/var/lib
    mkdir -p /btrfs_tmp/persist/system/etc/ssh

    if [ -e "/btrfs_tmp/root/etc/ssh/ssh_host_ed25519_key" ] && [ ! -e "/btrfs_tmp/persist/system/etc/ssh/ssh_host_ed25519_key" ]; then
      mv /btrfs_tmp/root/etc/ssh/ssh_host_ed25519_key /btrfs_tmp/persist/system/etc/ssh/ssh_host_ed25519_key
      mv /btrfs_tmp/root/etc/ssh/ssh_host_ed25519_key.pub /btrfs_tmp/persist/system/etc/ssh/ssh_host_ed25519_key.pub
    fi
    if [ -e "/btrfs_tmp/root/etc/ssh/ssh_host_rsa_key" ] && [ ! -e "/btrfs_tmp/persist/system/etc/ssh/ssh_host_rsa_key" ]; then
      mv /btrfs_tmp/root/etc/ssh/ssh_host_rsa_key /btrfs_tmp/persist/system/etc/ssh/ssh_host_rsa_key
      mv /btrfs_tmp/root/etc/ssh/ssh_host_rsa_key.pub /btrfs_tmp/persist/system/etc/ssh/ssh_host_rsa_key.pub
    fi

    # if file exists.
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root

    umount /btrfs_tmp
  '';

  fileSystems."/persist".neededForBoot = true;

  fileSystems."/etc/nixos" = {
    device = "/persist/system/etc/nixos";
    options = [ "bind" "noatime" ];
  };
  fileSystems."/var/log" = {
    device = "/persist/system/var/log";
    options = [ "bind" "noatime" ];
  };
  fileSystems."/var/lib" = {
    device = "/persist/system/var/lib";
    options = [ "bind" "noatime" ];
  };

  fileSystems."/etc/ssh/ssh_host_ed25519_key" = {
    device = "/persist/system/etc/ssh/ssh_host_ed25519_key";
    options = [ "bind" ];
    neededForBoot = true;  # sops need
  };
  fileSystems."/etc/ssh/ssh_host_ed25519_key.pub" = {
    device = "/persist/system/etc/ssh/ssh_host_ed25519_key.pub";
    options = [ "bind" ];
    neededForBoot = true;  # sops need
  };
  fileSystems."/etc/ssh/ssh_host_rsa_key" = {
    device = "/persist/system/etc/ssh/ssh_host_rsa_key";
    options = [ "bind" ];
    neededForBoot = true;  # sops need
  };
  fileSystems."/etc/ssh/ssh_host_rsa_key.pub" = {
    device = "/persist/system/etc/ssh/ssh_host_rsa_key.pub";
    options = [ "bind" ];
    neededForBoot = true;  # sops need
  };

  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      bits = 4096;
      path = "/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
    }
  ];

}