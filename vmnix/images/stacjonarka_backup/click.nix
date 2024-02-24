{ pkgs, lib, config, ... }: {

  systemd.services.clickhouse.serviceConfig.ExecStart = lib.mkForce "${pkgs.clickhouse}/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml";
  services.clickhouse.enable = true;

}
