{ inputs, ... }:

{
  perSystem = { inputs', self', system, ... }: {
    packages.my_zome =
      inputs.holochain-nix-builders.outputs.builders.${system}.rustZome {
        workspacePath = inputs.self.outPath;
        crateCargoToml = ./Cargo.toml;
        # matchingZomeHash = inputs'.previousZomeVersion.packages.my_zome;
      };

    checks.my_zome =
      inputs.holochain-nix-builders.outputs.builders.${system}.sweettest {
        workspacePath = inputs.self.outPath;
        dna = (inputs.holochain-nix-builders.outputs.builders.${system}.dna {
          dnaManifest = builtins.toFile "dna.yaml" ''
            ---
            manifest_version: "1"
            name: my_dna
            integrity:
              network_seed: ~
              properties: ~
              zomes: []
            coordinator:
              zomes:
                - name: my_zome
                  hash: ~
                  dependencies: []
          '';
          zomes = { my_zome = self'.packages.my_zome; };
        }).meta.debug;
        crateCargoToml = ./Cargo.toml;
      };
  };
}

