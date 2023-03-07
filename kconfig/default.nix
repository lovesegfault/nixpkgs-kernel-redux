{ stdenv
, buildPackages
, lib
, writeText

, autokernel
, python3

  # needed for kernels >=4.16
, bison ? null
, flex ? null

  # needed for kernels >=5.2
, pahole ? null
}:

{ pname
, version
, src
, patches ? [ ]
, makeFlags ? [ ]

, baseConfig ? stdenv.hostPlatform.linux-kernel.baseConfig
, configOptions ? { }
, extraConfigOptions ? { }
}:
assert (lib.versionAtLeast version "4.16") -> (bison != null && flex != null);
assert (lib.versionAtLeast version "5.2") -> (pahole != null);
let
  configOptions' =
    if configOptions == { }
    then import ./config.nix { inherit stdenv lib version; }
    else configOptions;
  configEval = lib.evalModules {
    modules = [
      (import ./module.nix)
      { settings = configOptions'; }
      { settings = extraConfigOptions; }
    ];
  };

  # FIXME: Respect baseConfig
  autokernelScript = writeText "${pname}-${version}-autokernel.lua" (''
    load_kconfig_unchecked(kernel_dir .. "/arch/x86/configs/x86_64_defconfig")
  '' + configEval.config.autokernelConfig);

  autokernelConfig = writeText "${pname}-${version}-autokernel.toml" ''
    [config]
    script = "${autokernelScript}"
  '';
in

stdenv.mkDerivation {
  pname = "${pname}-config";

  inherit version src patches makeFlags;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [ autokernel python3 ]
    ++ lib.optionals (lib.versionAtLeast version "4.16") [ bison flex ]
    ++ lib.optionals (lib.versionAtLeast version "5.2") [ pahole ];

  dontConfigure = true;

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild
    export HOSTCC=$CC_FOR_BUILD
    export HOSTCXX=$CXX_FOR_BUILD
    export HOSTAR=$AR_FOR_BUILD
    export HOSTLD=$LD_FOR_BUILD

    export RUST_BACKTRACE=1
    autokernel --kernel-dir "." --config "${autokernelConfig}" generate-config

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv .config $out
    runHook postInstall
  '';

  dontFixup = true;

  passthru = { inherit baseConfig configOptions extraConfigOptions autokernelScript; };
}
