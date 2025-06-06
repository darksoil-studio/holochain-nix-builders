# Build a hApp
{ happManifest, runCommandNoCC, hc, holochain, writeText, json2yaml, callPackage
, runCommandLocal, dnas ? { }, meta }:

let
  dnaSrcs = builtins.attrValues dnas;

  # Recurse over the DNA roles, and add the correct bundled DNA package by name

  manifest = (callPackage ./import-yaml.nix { }) happManifest;
  dnaToBundled = role:
    role // {
      dna = role.dna // { bundled = "./${role.name}.dna"; };
    };

  manifest' = manifest // { roles = builtins.map dnaToBundled manifest.roles; };

  happManifestJson = writeText "happ.json" (builtins.toJSON manifest');
  happManifestYaml = runCommandLocal "json-to-yaml" { }
    "	${json2yaml}/bin/json2yaml ${happManifestJson} $out\n";

  debug = runCommandLocal "${manifest.name}-debug" {
    srcs = builtins.map (dna: dna.meta.debug) dnaSrcs;
  } ''
      mkdir workdir
        
      cp ${happManifestYaml} workdir/happ.yaml

      ${
        builtins.toString (builtins.map (role: ''
          cp ${dnas.${role.name}.meta.debug} ./workdir/${role.name}.dna 
        '') manifest.roles)
      }

    	${hc}/bin/hc app pack workdir
    	mv workdir/${manifest.name}.happ $out
  '';

in runCommandNoCC manifest.name {
  meta = meta // { inherit debug; };
  srcs = dnaSrcs;
  outputs = [ "out" "dna_hashes" ];
} ''
    mkdir workdir

  	cp ${happManifestYaml} workdir/happ.yaml

    ${
      builtins.toString (builtins.map (role: ''
        cp ${dnas.${role.name}} ./workdir/${role.name}.dna 
      '') manifest'.roles)
    }

  	${hc}/bin/hc app pack workdir
  	mv workdir/${manifest.name}.happ $out

    export DNA_HASHES=
    ${
      builtins.toString (builtins.map (role: ''
        export DNA_HASHES=$DNA_HASHES:$(cat ${dnas.${role.name}.hash}) 
      '') manifest'.roles)
    }
    export DNA_HASHES="''${DNA_HASHES:1}"
    
    echo $DNA_HASHES > $dna_hashes
''
