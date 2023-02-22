{ lib, buildLinuxKernel }:
let
  releases = builtins.fromJson (builtins.readFile ./releases.json);
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

        bar = "";
        baz = "";
      in
      { name = ""; value = ""; })
    releases.releases;
in
{ }
