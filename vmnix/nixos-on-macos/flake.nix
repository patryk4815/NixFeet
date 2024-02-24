{
  outputs = {
    self,
    nixpkgs,
  }: {
    nixosModules.base = {pkgs, ...}: {
      system.stateVersion = "23.05";

      # Configure networking
      networking.useDHCP = false;
      networking.interfaces.eth0.useDHCP = true;

      # Create user "test"
      services.getty.autologinUser = "test";
      users.users.test.isNormalUser = true;
      users.users.test.password = "test";

      # Enable passwordless ‘sudo’ for the "test" user
      users.users.test.extraGroups = ["wheel"];
      security.sudo.wheelNeedsPassword = false;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      services.openssh.enable = true;
      services.openssh.settings.X11Forwarding = true;
      programs.ssh.setXAuthLocation = true;

      boot.kernelParams = [
          "mitigations=off"
          "quiet"
      ];
    };
    nixosModules.intel = {pkgs, ...}: {
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = [
        pkgs.quartus-prime-lite
      ];
    };
    nixosConfigurations.linuxVM = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.base
      ];
    };
    nixosConfigurations.darwinVM = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.base
#        self.nixosModules.intel
        {
          virtualisation.vmVariant.virtualisation = {
            host.pkgs = nixpkgs.legacyPackages.x86_64-darwin;
            graphics = false;

            useNixStoreImage = true;
            writableStore = true;
            writableStoreUseTmpfs = false;

#            qemu.networkingOptions = [
#              "-net nic,netdev=user.1,model=virtio"
#              "-netdev user,id=user.1,hostfwd=tcp::2223-:22"
#            ];
            cores = 4;
            memorySize = 4096;
#            diskSize = 20 * 512;
#            msize = 262144;
          };
        }
      ];
    };
    packages.x86_64-linux.linuxVM = self.nixosConfigurations.linuxVM.config.system.build.vm;
    packages.x86_64-darwin.darwinVM = self.nixosConfigurations.darwinVM.config.system.build.vm;
  };
}