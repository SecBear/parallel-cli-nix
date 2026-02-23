{
  description = "Nix flake for parallel-cli - AI-powered web search & research CLI from parallel.ai";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          parallel-cli = pkgs.callPackage ./package.nix { };
        in
        {
          default = parallel-cli;
          inherit parallel-cli;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.parallel-cli}/bin/parallel-cli";
        };
      });

      devShells = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            buildInputs = [ self.packages.${system}.parallel-cli ];
          };
        }
      );

      overlays.default = final: prev: {
        parallel-cli = final.callPackage ./package.nix { };
      };
    };
}
