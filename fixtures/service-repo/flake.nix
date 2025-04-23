{
  description = "Template for Holochain app development";

  inputs = {
    nixpkgs.follows = "holonix/nixpkgs";
    holonix.url = "github:holochain/holonix/main-0.5";

    holochain-nix-builders.url = "path:./../..";
    module = {
      url = "path:./../module-repo";
      inputs.holochain-nix.follows = "holochain-nix-builders";
    };
    profiles-zome.url = "github:darksoil-studio/profiles-zome/main-0.5";

    # previousDnaVersion.url =
    #   "github:darksoil-studio/holochain-nix-builders/cab12a7cfe0c7da510f4887b7bc93321cd0b6960?dir=fixtures/service-repo";
  };

  outputs = inputs@{ ... }:
    inputs.holonix.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./dna/dna.nix ];

      systems = builtins.attrNames inputs.holonix.devShells;
      perSystem = { inputs', config, pkgs, system, lib, self', ... }: {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ inputs'.holonix.devShells.default ];
          packages = [ pkgs.pnpm pkgs.nodejs_20 ];
        };
      };
    };
}
