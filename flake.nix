{
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
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
        settings = {
          statix.ignore = [ "kconfig/config.nix" ];
        };
        hooks = {
          black.enable = true;
          isort.enable = true;
          ruff.enable = true;

          nixpkgs-fmt = {
            enable = true;
            excludes = [ "kconfig/config.nix" ];
          };
          statix.enable = true;
        };
      };

      devShells.default = pkgs.mkShell {
        name = "nixpkgs-kernel-redux";
        nativeBuildInputs = with pkgs; [
          cachix
          nix-build-uncached
          nixpkgs-fmt
          rnix-lsp
          statix

          (python3.withPackages (p: with p; [ black mypy isort ]))
          pyright
          ruff
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
