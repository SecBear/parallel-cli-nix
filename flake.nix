{
  description = "Nix flake for parallel-cli - AI-powered web search & research CLI from parallel.ai";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, system, lib, ... }:
        let
          parallel-cli = pkgs.callPackage ./package.nix { };
        in
        {
          packages = {
            default = parallel-cli;
            inherit parallel-cli;
          };

          apps.default = {
            type = "app";
            program = "${parallel-cli}/bin/parallel-cli";
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [ parallel-cli ];
          };
        };

      flake = {
        overlays.default = final: prev: {
          parallel-cli = final.callPackage ./package.nix { };
        };
      };
    };
}
