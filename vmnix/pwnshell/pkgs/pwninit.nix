{ lib
, fetchFromGitHub
, makeWrapper
, pkg-config
, lzma
, patchelf
, elfutils
, openssl
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "pwninit";
  version = "3.2.0";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    lzma
    openssl
  ];

  postFixup = ''
    wrapProgram $out/bin/pwninit \
      --set PATH ${lib.makeBinPath [
        elfutils
        patchelf
      ]}
  '';

  src = fetchFromGitHub {
    owner = "io12";
    repo = pname;
    rev = version;
    sha256 = "sha256-XKDYJH2SG3TkwL+FN6rXDap8la07icR0GPFiYcnOHeI=";
  };

  cargoSha256 = "sha256-2HCHiU309hbdwohUKVT3TEfGvOfxQWtEGj7FIS8OS7s=";

  meta = with lib; {
    description = "A tool for automating starting binary exploit challenges";
    homepage = "https://github.com/io12/pwninit";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ msm ];
  };
}