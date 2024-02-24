{config, lib, pkgs, ...}: {
  environment.systemPackages = [ pkgs.jool-cli ];
  
  #boot.extraModulePackages = with config.boot.kernelPackages; [ jool ];
  boot.extraModulePackages = [ pkgs.linuxPackages_5_15.jool ];
  systemd.services.jool = {
    serviceConfig = {
      ExecStartPre = "${pkgs.kmod}/bin/modprobe jool";
      ExecStart =
        "${pkgs.jool-cli}/bin/jool instance add default --netfilter --pool6 64:ff9b::/96";
      ExecStop = "${pkgs.jool-cli}/bin/jool instance remove default";
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };

  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

  boot.kernel.sysctl = {
    # we want to forward packets from the ISP to the client and back.
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.disable_ipv6" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;
  };

  # make the network-online target a requirement, we wait for it in our test script
  #systemd.targets.network-online.wantedBy = [ "multi-user.target" ];
  networking.resolvconf.enable = lib.mkForce false;

  environment.etc = {
    "resolv.conf".text = "nameserver 2606:4700:4700::64\n";
  };

  networking = {
    hostName = "nixos";
    extraHosts = ''
##151.101.114.217 cache.nixos.org
'';
    useDHCP = false;
    firewall.enable = false;
    useNetworkd = true;
    nftables = {
      enable = true;
      ruleset = ''
      table inet filter {
        chain output {
          type filter hook output priority 100; policy accept;
        }

        chain input {
          type filter hook input priority filter; policy drop;

          # dhcp v6
          meta nfproto ipv6 udp sport 547 counter accept

          # icmp v6
          ip6 nexthdr ipv6-icmp counter accept

          # icmp v4
          ip protocol icmp counter accept

          # Allow trusted networks to access the router
          iifname {
            "enp6s0",
          } counter accept

          # Allow WP connect here
          iifname "ppp0" ip6 saddr 2001:67c:234c::/48 counter accept
          iifname "ppp0" ip6 saddr 2001:67c:25c4::/48 counter accept

          # Allow returning traffic from ppp0 and drop everthing else
          iifname "ppp0" ct state { established, related } counter accept
          iifname "ppp0" counter drop
          
          # Allow returning traffic from ppp1 and drop everthing else
          iifname "ppp1" ct state { established, related } counter accept
          iifname "ppp1" counter drop
        }

        chain forward {
          type filter hook forward priority filter; policy drop;
          meta l4proto ipv6-icmp counter accept

          # Allow WP connect here
          iifname "ppp0" ip6 saddr 2001:67c:234c::/48 counter accept
          iifname "ppp0" ip6 saddr 2001:67c:25c4::/48 counter accept

          # Allow trusted network WAN access
          iifname {
                  "enp6s0",
          } oifname {
                  "ppp0",
          } counter accept

          # Allow established WAN to return
          iifname {
                  "ppp0",
          } oifname {
                  "enp6s0",
          } ct state established,related counter accept
        }
      }
      '';
    };
  };

#  systemd.services.systemd-networkd-wait-online.serviceConfig.ExecStart = [
#    "" # clear old command
#    "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --ignore ppp0"
#  ];

  services.pppd = {
    enable = true;
    #enable = false;
    peers = {
      wanv6 = {
        # Autostart the PPPoE session on boot
        autostart = true;
        enable = true;
        config = ''
          plugin rp-pppoe.so wan.35
          #+ipv6
          # pppd supports multiple ways of entering credentials,
          # this is just 1 way
          name "bez_ochrony-qX9qQGL@neostrada.pl/ipv6"
          password "QwzZzY3STpCj!"

          persist
          maxfail 0
          holdoff 5

          noipdefault
          defaultroute
        '';
      };
      wanv4 = {
        # Autostart the PPPoE session on boot
        autostart = true;
        enable = true;
        config = ''
          plugin rp-pppoe.so wan.35
          #+ipv6
          # pppd supports multiple ways of entering credentials,
          # this is just 1 way
          name "bez_ochrony-qX9qQGL@neostrada.pl"
          password "QwzZzY3STpCj!"

          persist
          maxfail 0
          holdoff 5

          noipdefault
          defaultroute
        '';
      };
    };
  };
  systemd.targets.pppd.after = [ "sys-subsystem-net-devices-wan.35.device" ];

  services.resolved.enable = false;
  systemd.network = {
    netdevs."wan.35" = {
      enable = true;
      netdevConfig = {
        Kind = "vlan";
        Name = "wan.35";
      };
      vlanConfig = {
        Id = 35;
      };
    };
    networks = {
      "00-wlp5s0" = {
        enable = false;
        name = "wlp5s0";
      };
      "00-eno1" = {
        enable = true;
        matchConfig = {
          Name = "eno1";
          Type = "ether";
        };
        networkConfig = {
          LinkLocalAddressing = "no";
          LLDP = false;
          EmitLLDP = false;
          IPv6AcceptRA = false;
          IPv6SendRA = false;
          VLAN = [ "wan.35" ];
        };
      };
      "01-wan.35" = {
        enable = true;
        matchConfig = {
          Name = "wan.35";
          Type = "vlan";
        };
        networkConfig = {
          Description = "My vlan on wan.35";
          LinkLocalAddressing = "no";
          LLDP = false;
          EmitLLDP = false;
          IPv6AcceptRA = false;
          IPv6SendRA = false;
        };
      };

      "01-lo" = {
        name = "lo";
        addresses = [
          { addressConfig.Address = "fd42::1/128"; }
        ];
      };

      "02-ppp0" = {
        enable = true;
        matchConfig = {
          Name = "ppp0";
          Type = "ppp";
        };
        networkConfig = {
          Description = "ISP interface";
          DHCP = "ipv6";
          #DefaultRouteOnDevice = true;
          KeepConfiguration = "static";
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
        };
        linkConfig = {
          RequiredForOnline = false;
        };
        dhcpV6Config = {
          PrefixDelegationHint = "::/56";
          UseDNS = false;
          UseNTP = false;
        };
        ipv6SendRAConfig = {
          Managed = true;
          OtherInformation = true;
        };
        ipv6AcceptRAConfig = {
          UseDNS = false;
          DHCPv6Client = true;
        };
      };

      "03-enp6s0" = {
        enable = true;
        name = "enp6s0";
        networkConfig = {
          LinkLocalAddressing = "ipv6";
          Description = "Client interface";
          DHCPPrefixDelegation = true;
          EmitLLDP = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
        };

        dhcpPrefixDelegationConfig = {
          SubnetId = 1;
        };

        ipv6SendRAConfig = {
          RouterLifetimeSec = 300;
          EmitDNS = true;
          #EmitDomains = true;
          DNS = "2606:4700:4700::64";
        };

        ipv6Prefixes = [
            {
                ipv6PrefixConfig = {
                    Prefix = "fd66:a562:1af6:1::/64";
                };
            }
        ];
      };

    };
  };


}
