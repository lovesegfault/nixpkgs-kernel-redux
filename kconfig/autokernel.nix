{ lib
, fetchFromGitHub
, fetchurl
, rustPlatform

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
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "oddlama";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-upiENXRYVSZMPLcb9DeUx0FR97rMbW/sEAlYKi9dvI4=";
  };

  cargoHash = "sha256-yE9vIcy4OJrGyQPWnUAIyliiVsNews/CZfxwTmudXyU=";

  # XXX: These are very tricky to run, so we don't
  # TODO: Get tests to work
  doCheck = false;
  # nativeCheckInputs = [
  #   bison
  #   flex
  #   gcc
  #   python3
  # ];
  # preCheck = ''
  #   test_dir="$TMPDIR/autokernel-test"
  #   mkdir -p "$test_dir"
  #   ln -s "${kernelTestArchive}" "$test_dir/linux-${kernelTestVersion}.tar.xz"
  # '';

  meta = with lib; { };
}
