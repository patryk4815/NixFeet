{ inputs, lib, config, ... }:
{
  options = {
    nixCommunity.fqdn = lib.mkOption {
      type = lib.types.str;
      default = throw "nixCommunity.fqdn is empty";
      description = "fqdn for machine";
    };
  };

  config = let
    fqdnParts = builtins.match "([^.]+)[.](.+)" config.nixCommunity.fqdn;
    hostName = builtins.elemAt fqdnParts 0;
    domain = builtins.elemAt fqdnParts 1;
  in {
    networking.hostName = hostName;
    networking.domain = domain;
    boot.kernel.sysctl."kernel.hostname" = config.networking.fqdn;
  };
}