{ config, inputs, lib, ... }:
let
  defaultSopsPath = "${toString inputs.self}/hosts/${config.networking.fqdn}/secrets/secrets.yaml";
  sopsExists = builtins.pathExists defaultSopsPath;
in
{
  sops.defaultSopsFile = lib.mkIf sopsExists defaultSopsPath;

  sops.secrets = lib.mkIf sopsExists {
    root-password-hash.neededForUsers = true;
  };
  users.users.root = {
    hashedPasswordFile = lib.mkIf sopsExists config.sops.secrets.root-password-hash.path;
  };
}
