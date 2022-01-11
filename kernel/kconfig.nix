{ stdenv
, buildPackages
, lib
, writeText

  # needed only for kernels >=4.16
, bison ? null
, flex ? null
}:

{ pname
, version
, src
, patches ? [ ]
, makeFlags ? [ ]
, baseConfig ? stdenv.hostPlatform.linux-kernel.baseConfig
}:

assert (lib.versionAtLeast version "4.16") -> (bison != null && flex != null);

extraConfig:

let
  mkConfigLine = k: v:
    if v == null then "# CONFIG_${k} is not set\n"
    else "CONFIG_${k}=${v}\n";

  mkConfig = cfg: lib.concatStrings (lib.mapAttrsToList mkConfigLine cfg);

  extraConfigFile = writeText "${pname}-extra-config-${version}" (mkConfig extraConfig);
in

stdenv.mkDerivation {
  pname = "${pname}-config";

  inherit version src patches makeFlags;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [ ]
    ++ lib.optionals (lib.versionAtLeast version "4.16") [ bison flex ];

  dontConfigure = true;

  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild
    export HOSTCC=$CC_FOR_BUILD
    export HOSTCXX=$CXX_FOR_BUILD
    export HOSTAR=$AR_FOR_BUILD
    export HOSTLD=$LD_FOR_BUILD

    # first we build the base config we want to iterate on
    make $makeFlags -C . ${baseConfig}

    # then we merge that with our extraConfig
    ./scripts/kconfig/merge_config.sh .config ${extraConfigFile}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv .config $out
    runHook postInstall
  '';

  dontFixup = true;

  passthru = { inherit baseConfig extraConfig; };
}
