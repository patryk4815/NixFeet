{ lib
, stdenv
, libusb
, fetchFromGitHub
}:
stdenv.mkDerivation rec {
  pname = "usb-proxy";
  version = "main";
  format = "other";

  src = fetchFromGitHub {
    owner = "AristoChen";
    repo = "usb-proxy";
    rev = version;
    sha256 = "sha256-y+gF7ho/Y1pifnjkkEUahPOxWIZVdogbBfAiIcQxM/w=";
  };

  nativeBuildInputs = [ libusb ];

  installPhase = ''
    mkdir -p $out/bin/
    cp usb-proxy $out/bin/
  '';

  meta = with lib; {
    description = "This software is a USB proxy based on raw-gadget and libusb. It is recommended to run this repo on a computer that has an USB OTG port, such as Raspberry Pi 4 or other hardware that can work with raw-gadget, otherwise might need to use dummy_hcd kernel module to set up virtual USB Device and Host controller that connected to each other inside the kernel.";
    homepage = "https://github.com/AristoChen/usb-proxy";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ msm ];
  };
}