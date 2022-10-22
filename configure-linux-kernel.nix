{ stdenv
, buildPackages
, lib
, writeText

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
  # , baseConfig ? stdenv.hostPlatform.linux-kernel.baseConfig
, baseConfig ? "allmodconfig"
, extraConfig ? { }
}:
assert (lib.versionAtLeast version "4.16") -> (bison != null && flex != null);
assert (lib.versionAtLeast version "5.2") -> (pahole != null);
let
  configEval = lib.evalModules {
    modules = [
      (import ./module.nix)
      { settings = import ./common-config.nix { inherit stdenv lib version; }; }
      { settings = extraConfig; }
    ];
  };

  extraConfigFile = writeText "${pname}-extra-config-${version}"
    configEval.config.intermediateNixConfig;
in

stdenv.mkDerivation {
  pname = "${pname}-config";

  inherit version src patches makeFlags;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [ ]
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

  doInstallCheck = true;

  installCheckPhase = ''
    declare -A knownOptions

    configuredOptions="${placeholder "out"}"
    providedOptions="${extraConfigFile}"

    while read -r line; do
        if [[ "$line" =~ ^([A-Z0-9_]+)=(.+)$ ]]; then
            k=''${BASH_REMATCH[1]}
            v=''${BASH_REMATCH[2]}
            knownOptions[$k]=$v
        fi
    done < "$configuredOptions"


    rc=0
    while read -r line; do
        if [[ "$line" =~ ^([A-Z0-9_]+)=(.+)$ ]]; then
            k=''${BASH_REMATCH[1]}
            v=''${BASH_REMATCH[2]}
            if ! [ "''${knownOptions[$k]+abc}" ]; then
                if [ "$v" != "n" ]; then
                  printf "option '$k' was not set in the configfile (wanted '$v')\n" >&2
                  rc=1
                fi
            elif [[ "''${knownOptions[$k]}" != "$v" ]]; then
                printf "option '$k' was set to '$v' but the build configured it to ''${knownOptions[$k]}\n" >&2
                rc=1
            fi
        fi
    done < "$providedOptions"

    # [[ $rc == 0 ]] || exit $rc
  '';

  dontFixup = true;

  passthru = { inherit baseConfig extraConfig extraConfigFile; };
}
