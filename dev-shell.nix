{ self, ... }:

system:

with self.nixpkgs.${system};

mkShell {
  name = "nixpkgs-kernel-redux";

  nativeBuildInputs = [
    cachix
    nix-build-uncached
    nix-linter
    nixpkgs-fmt
    pre-commit
    rnix-lsp
  ];

  shellHook = ''
    ${self.checks.${system}.pre-commit-check.shellHook}
  '';
}
