{ lib }:
with lib;
{
  whenAtLeast = ver: mkIf (versionAtLeast version ver);
  whenOlder = ver: mkIf (versionOlder version ver);
  # range is (inclusive, exclusive)
  whenBetween = verLow: verHigh: mkIf (versionAtLeast version verLow && versionOlder version verHigh);
}
