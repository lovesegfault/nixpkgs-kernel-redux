{
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils, ... }@inputs: {
    overlay = import ./overlay.nix;
  } // utils.lib.eachDefaultSystem (system: {
    checks = import ./checks.nix inputs system;

    devShell = import ./dev-shell.nix inputs system;

    nixpkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlay ];
    };

    packages = {
      inherit (self.nixpkgs.${system}) testConfig;
    };
  });
}
