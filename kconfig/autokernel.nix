{ lib
, fetchFromGitHub
, fetchurl
, rustPlatform
, bash

, stdenv
, bison
, flex
, gcc
, python3
}:
let
  # XXX: When updating this package, look at
  # https://github.com/oddlama/autokernel/blob/main/tests/setup_teardown.rs
  # and update kernelTestVersion
  kernelTestVersion = "5.19.1";
  kernelTestArchive = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${kernelTestVersion}.tar.xz";
    hash = "sha256-9OJ7km6ixmuAjbH1cGJUz5KoiZ4hCO7bDDp9Ekma6lU=";
  };
in
rustPlatform.buildRustPackage rec {
  pname = "autokernel";
  version = "unstable-2023-03-07";

  src = fetchFromGitHub {
    owner = "oddlama";
    repo = pname;
    rev = "e50c6b1eb4732ef48f8f748bee5292b67d6ac799";
    hash = "sha256-JyT+w93ONa/79vQ4uG57MbVrfkgcoC2dnga5cLehzS4=";
  };

  cargoHash = "sha256-GG9HHYrxJYeKAwj0ZVZ/J47lQS0XpV3R4sQna3IQi0I=";

  propagatedBuildInputs = [ bash ];

  postPatch = ''
    chmod +x src/bridge/cbridge/interceptor.sh
    patchShebangs --host src/bridge/cbridge/interceptor.sh
  '';

  doCheck = stdenv.hostPlatform == stdenv.buildPlatform;
  nativeCheckInputs = [
    bison
    flex
    gcc
    python3
  ];
  preCheck = ''
    test_dir="$TMPDIR/autokernel-test"
    mkdir -p "$test_dir"
    ln -s "${kernelTestArchive}" "$test_dir/linux-${kernelTestVersion}.tar.xz"
  '';

  meta = with lib; { };
}
