let
    over0 = (self: super: rec {

    });
    over1 = (self: super: rec {
      pwninit = self.callPackage ./pkgs/pwninit.nix {};
    });

    pkgs = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz) {
        overlays = [ over0 over1 ];
    };
in
    pkgs.mkShell {
        nativeBuildInputs = [
            pkgs.pwninit
        ];
    }
