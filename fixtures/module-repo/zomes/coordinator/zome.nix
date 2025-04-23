{ inputs, ... }:

{
  perSystem = { inputs', self', system, ... }: {
    packages.my_zome =
      inputs.holochain-nix-builders.outputs.builders.${system}.rustZome {
        workspacePath = inputs.self.outPath;
        crateCargoToml = ./Cargo.toml;
        # matchingZomeHash = inputs'.previousZomeVersion.packages.my_zome;
      };

  };
}

