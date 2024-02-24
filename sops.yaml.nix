# To update .sops.yaml:
# $ inv update-sops-files
let
  mapAttrsToList = f: attrs:
    map (name: f name attrs.${name}) (builtins.attrNames attrs);

  renderPermissions = (attrs: mapAttrsToList
    (path: keys: {
      path_regex = path;
      key_groups = [{
        age = keys ++ groups.admins;
      }];
    })
    attrs);

  # command to add a new age key for a new host
  # inv print-age-key --hosts "host1,host2"
  keys = builtins.fromJSON (builtins.readFile ./pubkeys.json);
  groups = {
    admins = builtins.attrValues keys.admins;
    all = builtins.attrValues (keys.admins // keys.machines);
  };

  secretsMachines = builtins.listToAttrs (mapAttrsToList (hostname: key: {
    name = "hosts/${hostname}/secrets/.+$";
    value = [ key ];
  }) keys.machines);

  secretsByGroup = {
#    "secrets.yml$" = [ ];
#    "modules/secrets.yml$" = groups.all;
  };

  secretsByMachine = builtins.mapAttrs (name: value: (map (x: keys.machines.${x}) value)) {
#    "modules/nfs/secrets.yml$" = [ "nfs-1.pl" "nfs-2.pl" ];
#    "modules/k3s/secrets.yml$" = [ "kube-1.pl" "kube-2.pl" "kube-3.pl" ];
  };

  sopsPermissions = secretsMachines // secretsByGroup // secretsByMachine;
in
{
  creation_rules = [
    # example:
    #{
    #  path_regex = "foobar.yaml$";
    #  key_groups = [
    #    {age = groups.admin ++ [
    #      "key3"
    #    ];}
    #  ];
    #}
  ] ++ (renderPermissions sopsPermissions);
}