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
            mkConfigLine = k: v:
              if v == null
              then "-- ${k} is not set\n"
              else "${k}:satisfy { \"${v}\", recursive = true }\n";
          in
          concatStrings (mapAttrsToList mkConfigLine exprs);
      in
      generateKernelConfig config.settings;
  };
}
