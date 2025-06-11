{
  inputs = {
    holonix.url = "github:holochain/holonix/main-0.5";

    custom-holonix.url = "github:holochain/holonix/main-0.5";
    holochain.url = "github:guillemcordoba/holochain/develop-0.5";
    custom-holonix.inputs.holochain.follows = "holochain";

    nixpkgs.follows = "holonix/nixpkgs";
    rust-overlay.follows = "holonix/rust-overlay";
    crane.follows = "holonix/crane";
  };

  nixConfig = {
    extra-substituters = [
      "https://holochain-ci.cachix.org"
      "https://darksoil-studio.cachix.org"
    ];
    extra-trusted-public-keys = [
      "holochain-ci.cachix.org-1:5IUSkZc0aoRS53rfkvH9Kid40NpyjwCMCzwRTXy+QN8="
      "darksoil-studio.cachix.org-1:UEi+aujy44s41XL/pscLw37KEVpTEIn8N/kn7jO8rkc="
    ];
  };

  outputs = inputs@{ ... }:
    inputs.holonix.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        flakeModules.builders = ./nix/builders-option.nix;
        flakeModules.dependencies = ./nix/dependencies-option.nix;
      };

      imports = [
        ./crates/compare_dnas_integrity/default.nix
        ./crates/zome_wasm_hash/default.nix
        ./nix/builders-option.nix
        ./nix/dependencies-option.nix
      ];

      systems = builtins.attrNames inputs.holonix.devShells;

      perSystem = { inputs', self', config, pkgs, system, lib, ... }: rec {
        builders = {
          rustZome = { crateCargoToml, workspacePath, cargoArtifacts ? null
            , matchingZomeHash ? null, meta ? { }, zomeEnvironmentVars ? { }
            , excludedCrates ? [ ] }:
            let
              deterministicCraneLib = let
                rustToolchain =
                  inputs.holonix.outputs.packages."x86_64-linux".rust;
              in (inputs.crane.mkLib
                inputs.holonix.inputs.nixpkgs.outputs.legacyPackages.${
                  "x86_64-linux"
                }).overrideToolchain rustToolchain;

              craneLib = (inputs.crane.mkLib pkgs).overrideToolchain
                inputs'.holonix.packages.rust;
              zome-wasm-hash = self'.packages.zome-wasm-hash;

            in pkgs.callPackage ./nix/zome.nix {
              inherit deterministicCraneLib craneLib crateCargoToml
                cargoArtifacts workspacePath matchingZomeHash zome-wasm-hash
                meta zomeEnvironmentVars excludedCrates;
            };
          dna = { dnaManifest, zomes, matchingIntegrityDna ? null, meta ? { } }:
            pkgs.callPackage ./nix/dna.nix {
              inherit zomes dnaManifest matchingIntegrityDna meta;
              compare-dnas-integrity = self'.packages.compare-dnas-integrity;
              holochain = inputs'.holonix.packages.holochain;
              hc = inputs'.holonix.packages.hc;
            };
          happ = { happManifest, dnas, meta ? { } }:
            pkgs.callPackage ./nix/happ.nix {
              inherit dnas happManifest meta;
              holochain = inputs'.holonix.packages.holochain;
              hc = inputs'.holonix.packages.hc;
            };
          webhapp = { name, ui, happ, meta ? { } }:
            pkgs.callPackage ./nix/webhapp.nix {
              inherit name happ ui meta;
              holochain = inputs'.holonix.packages.holochain;
              hc = inputs'.holonix.packages.hc;
            };
        };

        dependencies.holochain.buildInputs =
          (with pkgs; [ perl cmake clang go ]);

        devShells.holochainDev = pkgs.mkShell {
          packages = [ inputs'.holonix.packages.rust ];
          buildInputs = self'.dependencies.holochain.buildInputs;

          shellHook = ''
            # Make sure libdatachannel can find C++ standard libraries from clang.
            export LIBCLANG_PATH=${pkgs.llvmPackages_18.libclang.lib}/lib
          '';
        };

        devShells.default = pkgs.mkShell {
          inputsFrom =
            [ devShells.holochainDev inputs'.holonix.devShells.default ];
          packages = [ pkgs.pnpm ];
        };

        packages.holochain =
          inputs'.custom-holonix.packages.holochain.override {
            cargoExtraArgs =
              " --features unstable-countersigning,unstable-functions";
          };
      };
    };
}
