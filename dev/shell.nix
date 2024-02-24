{ pkgs, lib, ... }:
{
  devShells = {
    default = with pkgs; mkShellNoCC {
      packages = [
        jq
        yq-go
#        mkpasswd # TODO: macos
        python3.pkgs.deploykit
        python3.pkgs.invoke

        # moja wersja pached'ed, bo sops official jeszcze nie wspiera pluginow TPM/yubikey/SecureEnclave
        (pkgs.buildGoModule {
          pname = "sops";
          version = "3.8.1";
          src = fetchFromGitHub {
            owner = "patryk4815";
            repo = "sops";
            rev = "6e657582c528dcc75580d3824c3b11824b816a30";
            hash = "sha256-Mznq7ev2uhBRzOotIeoCkc1l6KadTjnSO4hW20IaptQ=";
          };
          vendorHash = null;
          subPackages = [ "cmd/sops" ];
          ldflags = [ "-s" "-w" "-X github.com/getsops/sops/v3/version.Version=3.8.1" ];
        })
        ssh-to-age
      ];
    };
    sotp = with pkgs; mkShellNoCC {
      packages = [
        (buildGoModule rec {
          pname = "sotp";
          version = "e7f7c804b1641169ce850d8352fb07294881609e";
          src = pkgs.fetchFromGitHub {
            owner = "getsops";
            repo = "sotp";
            rev = version;
            hash = "sha256-Cu8cZCmM19G5zeMIiiaCwVJee8wrBZP3Ltk1jWKb2vs=";
          };
          vendorHash = "sha256-vQruuohwi53By8UZLrPbRtUrmNbmPt+Sku9hI5J3Dlc=";
          ldflags = [ "-s" "-w" ];
          doCheck = false;
        })
      ];
    };
  };
}