{config, lib, pkgs, ...}: {
  environment.systemPackages = with pkgs; [ hostapd dnsmasq bridge-utils ];

hardware.enableRedistributableFirmware = true;
  
services.hostapd = {
  enable = true;  
  interface = "wlp2s0";
  hwMode = "a";
  wpaPassphrase = "test12345678";
  ssid = "nixos";
  logLevel = 0;
  channel = 157;
  extraConfig = ''
wpa_pairwise=CCMP
ieee80211n=1
ieee80211ac=1
ieee80211ax=1
max_num_sta=128
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=163
require_ht=1
vht_capab=[SHORT-GI-80][MAX-MPDU-11454][MAX-A-MPDU-LEN-EXP7]
ht_capab=[HT20][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40][HT80][SHORT-GI-80]
country_code=PL
  '';
};

}
