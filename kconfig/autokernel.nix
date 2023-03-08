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
  version = "unstable-2023-03-08";

  src = fetchFromGitHub {
    owner = "oddlama";
    repo = pname;
    rev = "0e62fa7fd935309f0fc344982e9ed12314bb974f";
    hash = "sha256-t0in7JRP8QB3kVR2ALkhXLtj54m3layvk/Yr7cA5aEU=";
  };

  cargoHash = "sha256-W0r9obdKn71F2BK1EJJUwESX22TMpFdRrUYl9w21HoI=";

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
