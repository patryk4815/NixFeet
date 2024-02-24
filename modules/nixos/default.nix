let
  files = builtins.removeAttrs (builtins.readDir ./.) [ "default.nix" ];
in
builtins.mapAttrs (name: value: (./. + ("/" + name))) files
