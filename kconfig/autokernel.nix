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
  version = "unstable-2023-03-03";

  src = fetchFromGitHub {
    owner = "oddlama";
    repo = pname;
    rev = "ce3b4e29462c59376f7fa90742a18186ee15bcec";
    hash = "sha256-rfWVGd+NhkJiYvZOqKhKnBVlupyL/KwivSH7ovy5lkc=";
  };

  cargoHash = "sha256-mPJZ3mvts0+aOM0p3E4eUcsgoHseugWwEZI/rmznWJA=";

  propagatedBuildInputs = [ bash ];

  postPatch = ''
    chmod +x src/bridge/cbridge/interceptor.sh
    patchShebangs --host src/bridge/cbridge/interceptor.sh
    substituteInPlace src/bridge/cbridge/interceptor.sh \
      --replace "exec /bin/bash" 'exec "$BASH"'
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
