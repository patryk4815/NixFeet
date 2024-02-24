let
    over0 = (self: super: rec {

    });
    over1 = (self: super: rec {
      packageOverrides = self2: super2: {
        pwntools = self2.callPackage ./pkgs/pwntools.nix { debugger = super.gdb; };
      };
      python3 = super.python3.override { inherit packageOverrides; };
    });

    pkgs = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz) {
        overlays = [ over0 over1 ];
    };

    py = pkgs.python3.withPackages(ps: with ps; [
        pwntools
        ipython
    ]);
in
    pkgs.mkShell {
        nativeBuildInputs = [
            py
        ];
    }
