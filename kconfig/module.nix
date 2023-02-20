{ lib, config, ... }:

with lib;
{

  options = {
    intermediateNixConfig = mkOption {
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
    intermediateNixConfig =
      let
        generateKernelConfig = exprs:
          let
            isNumber = c: elem c [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
            mkConfigLine = k: v:
              if v == null then "# CONFIG_${k} is not set\n"
              else if v == "y" || v == "n" || v == "m" then "CONFIG_${k}=${v}\n"
              else if all isNumber (stringToCharacters v) then "CONFIG_${k}=${v}\n"
              else "CONFIG_${k}=\"${v}\"\n";
          in
          concatStrings (mapAttrsToList mkConfigLine exprs);
      in
      generateKernelConfig config.settings;
  };
}
