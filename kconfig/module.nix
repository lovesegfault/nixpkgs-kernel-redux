{ lib, config, ... }:

with lib;
{

  options = {
    autokernelConfig = mkOption {
      readOnly = true;
      type = types.lines;
    };
    settings = mkOption {
      type = types.attrsOf types.str;
      example = literalExpression ''{
        "9P_NET" = "yes";
        USB = "no";
        MMC_BLOCK_MINORS = "32";
      }'';
      description = lib.mdDoc ''
        Structured kernel configuration.
      '';
    };
  };

  config = {
    autokernelConfig =
      let
        generateKernelConfig = exprs:
          let
            isNumber = c: elem c [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" ];

            normalizeConfigKey = k:
              if isNumber (head (stringToCharacters k))
              then "CONFIG_${k}"
              else k;

            mkConfigLine = k: v:
              let
                k' = normalizeConfigKey k;
              in
              if v == "y" then "${k'}:satisfy { y, recursive = true }\n"
              else if v == "m" then "${k'}:satisfy { m, recursive = true }\n"
              else if v == "n" then "${k'}:set(n)\n"
              else "${k'}:set(\"${v}\")";
          in
          concatStrings (mapAttrsToList mkConfigLine exprs);
      in
      generateKernelConfig config.settings;
  };
}
