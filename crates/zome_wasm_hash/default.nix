{ inputs, ... }:

{
  perSystem = { inputs', pkgs, self', lib, ... }: {

    packages.zome-wasm-hash = let
      craneLib = inputs.crane.mkLib pkgs;

      cratePath = ./.;

      cargoToml =
        builtins.fromTOML (builtins.readFile "${cratePath}/Cargo.toml");
      crate = cargoToml.package.name;

      commonArgs = {
        src = craneLib.cleanCargoSource (craneLib.path ../../.);
        doCheck = false;
        buildInputs = self'.dependencies.holochain.buildInputs;
      };
      cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
        pname = crate;
        version = "0.5.x";
      });
    in craneLib.buildPackage (commonArgs // {
      pname = crate;
      version = cargoToml.package.version;
      inherit cargoArtifacts;
    });
  };
}

