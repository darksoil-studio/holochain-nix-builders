{
  description = "Template for Holochain app development";

  inputs = {
    nixpkgs.follows = "holonix/nixpkgs";
    holonix.url = "github:holochain/holonix/main-0.5";

    holochain-nix-builders.url = "path:./../..";
    # previousZomeVersion.url = "github:darksoil-studio/holochain-nix-builders/67dffe4af2c8675cd47d0b404fd0473d6a93ddfd?dir=fixtures/module-repo";
  };

  outputs = inputs@{ ... }:
    inputs.holonix.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./zomes/coordinator/zome.nix
        ./zomes/integrity/zome.nix
        inputs.holochain-nix-builders.flakeModules.builders
      ];

      systems = builtins.attrNames inputs.holonix.devShells;
      perSystem = { inputs', config, pkgs, system, lib, self', ... }: {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ inputs'.holonix.devShells.default ];
          packages = [ pkgs.pnpm pkgs.nodejs_20 ];
        };
      };
    };
}
