{ pkgs, lib, config, ... }: {
  services.openssh.enable = true;
  users.users = let
    user = builtins.getEnv "USER";
    keys = map (key: "${builtins.getEnv "HOME"}/.ssh/${key}") [
      "id_rsa.pub"
      "id_ecdsa.pub"
      "id_ed25519.pub"
    ];
    home = builtins.getEnv "HOME";
  in {
    ${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "lp" ];
      openssh.authorizedKeys.keyFiles = lib.filter builtins.pathExists keys;
      home = "/home/${user}";
      initialHashedPassword = "";
    };
  };

  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
    cache = "none"; # default is "loose"
  };

  virtualisation = {
    writableStoreUseTmpfs = false;
    writableStore = true;
    cores = 4;
    memorySize = "4096M";
    diskSize = 20 * 512;
    msize = 262144;

#   virtualisation.sharedDirectories = {
#      nix-store = { source = "/nix/store"; target = "/nix/store"; };
#      xchg      = { source = ''"$TMPDIR"/xchg''; target = "/tmp/xchg"; };
#      shared    = { source = ''"''${SHARED_DIR:-$TMPDIR/xchg}"''; target = "/tmp/shared"; };
#    };
    # use squashed store
#    shareNixStore = false;

    # virtfs mount
#    shareExchangeDir = true;

    qemu = {
      networkingOptions = [
        "-net nic,netdev=user.0,model=virtio"
        "-netdev user,id=user.0,hostfwd=tcp::2222-:22"
      ];
#      pkgs = import <nixpkgs> {
#        system = "x86_64-darwin";
#        overlays = [
#          (self: super: {
#            qemu = super.qemu.overrideAttrs (attrs: {
#              preConfigure = attrs.preConfigure
#                + "substituteInPlace meson.build --replace 'if exe_sign' 'if false'";
#            });
#          })
#        ];
#      };
    };
  };
}
