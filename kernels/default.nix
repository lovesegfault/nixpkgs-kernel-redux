{ lib, configureLinuxKernel, fetchurl }:
let
  releases = builtins.fromJSON (builtins.readFile ./releases.json);
  kernels = map
    (relInfo:
      let
        inherit (relInfo) version;
        major = lib.versions.major version;
        minor = lib.versions.minor version;

        name =
          if relInfo.moniker == "linux-next" then "linux-next"
          else if relInfo.moniker == "mainline" then "linux-testing"
          else "linux_${major}_${minor}";

        build = configureLinuxKernel {
          pname = "linux";
          inherit version;

          src = fetchurl {
            inherit (relInfo) src hash;
          };
        };
      in
      { inherit name; value = build; })
    releases.releases;
in
lib.listToAttrs kernels
