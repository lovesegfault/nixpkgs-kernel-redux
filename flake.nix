{
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    pre-commit = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, pre-commit, ... }: {
    overlays.default = final: _: {
      configureLinuxKernel = final.callPackage ./configure-linux-kernel.nix { };
    };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
    in
    {
      checks.pre-commit = pre-commit.lib.${system}.run {
        src = ./.;
        hooks = {
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };
      };

      devShells.default = pkgs.mkShell {
        name = "nixpkgs-kernel-redux";
        nativeBuildInputs = with pkgs; [
          cachix
          nix-build-uncached
          nix-linter
          nixpkgs-fmt
          rnix-lsp
          statix
        ];
        shellHook = ''
          ${self.checks.${system}.pre-commit.shellHook}
        '';
      };

      packages = {
        linuxKernelRedux_6_0 = pkgs.configureLinuxKernel {
          inherit (pkgs.linuxKernel.kernels.linux_6_0) patches pname version src makeFlags;
        };
      };
    });
}
