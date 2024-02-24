{ config, lib, pkgs, modulesPath, ... }:
{
    nixpkgs.config.allowUnsupportedSystem = true;
    nixpkgs.crossSystem.system = "armv7l-linux";

    boot.supportedFilesystems = lib.mkForce [ "vfat" "ext" ];

    services.openssh.enable = true;
    services.openssh.permitRootLogin = "yes";
    users.users.root.password = "nixos";

    networking = {
        firewall.enable = false;
        wireless.enable = true;
        hostName = "armv7";
        useDHCP = false;
        enableIPv6 = false;

        interfaces = {
            eth0 = {
                ipv4.addresses = [{address = "192.168.50.101"; prefixLength = 24;}];
                ipv4.routes = [{address = "0.0.0.0"; prefixLength = 0; via = "192.168.50.1";}];
            };
        };
        nameservers = [ "1.1.1.1" "8.8.8.8" ];
    };

    sdImage.populateFirmwareCommands = let
        ubootBananaPim2 = pkgs.buildUBoot {
            defconfig = "Sinovoip_BPI_M2_defconfig";
            extraMeta.platforms = ["armv7l-linux"];
            filesToInstall = ["u-boot-sunxi-with-spl.bin"];
          };
      in lib.mkForce ''
        cp ${ubootBananaPim2}/u-boot-sunxi-with-spl.bin firmware/u-boot-sunxi-with-spl.bin
      '';
    sdImage.postBuildCommands = lib.mkForce ''
        dd if=firmware/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
      '';

    hardware.firmware = [
        (
        let
            #driverPkg = builtins.fetchTarball {
            #    url = "https://mpow.s3-us-west-1.amazonaws.com/mpow_MPBH456AB_driver+for+Linux.tgz";
            #    sha256 = "0mq2jq0mhmh2mjxhbr74hgv63ji77n2vn4phfpg55x7j9kixjs1a";
            #};
            x = 1;
        in
            pkgs.runCommandNoCC "firmware-extra" { } ''
                mkdir -p $out/lib/firmware/RTL8192SU
                cp ${./firmware}/RTL8192SU/rtl8192sfw.bin $out/lib/firmware/RTL8192SU/rtl8192sfw.bin

                mkdir -p $out/lib/firmware/ap6210
                cp ${./firmware}/ap6210/bcm20710a1.hcd $out/lib/firmware/ap6210/bcm20710a1.hcd
                cp ${./firmware}/ap6210/fw_bcm40181a2.bin $out/lib/firmware/ap6210/fw_bcm40181a2.bin
                cp ${./firmware}/ap6210/fw_bcm40181a2_apsta.bin $out/lib/firmware/ap6210/fw_bcm40181a2_apsta.bin
                cp ${./firmware}/ap6210/fw_bcm40181a2_p2p.bin $out/lib/firmware/ap6210/fw_bcm40181a2_p2p.bin
                cp ${./firmware}/ap6210/nvram_ap6210.txt $out/lib/firmware/ap6210/nvram_ap6210.txt

                mkdir -p $out/lib/firmware/brcm
                cp ${./firmware}/brcm/brcmfmac43362-sdio.sinovoip,bpi-m2.bin $out/lib/firmware/brcm/brcmfmac43362-sdio.sinovoip,bpi-m2.bin
                cp ${./firmware}/brcm/brcmfmac43362-sdio.sinovoip,bpi-m2.txt $out/lib/firmware/brcm/brcmfmac43362-sdio.sinovoip,bpi-m2.txt
            ''
        )
    ];
}