{ pkgs, lib, hies, undotted }:
selector:
let
  selected = lib.unique (lib.attrValues (selector hies));

  ghc-versions = builtins.map (hie: hie.compiler.version) selected;

  versioned = builtins.map
    (
      hie:
      let
        v = hie.compiler.version;
        v-mm = lib.versions.majorMinor v;
        priority = - lib.toInt (undotted v);
        drv = lib.addMetaAttrs
          { inherit priority; }
          (
            pkgs.runCommandNoCCLocal
              hie.name
              { } ''
              mkdir -p $out/bin
              ln -s ${hie}/bin/hie $out/bin/hie-${v}
              ln -s ${hie}/bin/hie $out/bin/hie-${v-mm}
            ''
          );
      in
      drv
    )
    selected;

  newest = lib.head (
    lib.sort
      (a: b: builtins.compareVersions a.compiler.version b.compiler.version > -1)
      selected
  );

  dummy = pkgs.writeShellScriptBin "hie" ''
    echo We were unable to detect a matching HIE for the GHC used in your project

    ghc=$(command -v ghc)

    if [ -n "$ghc" ]; then
        v=$(ghc --numeric-version)
        echo
        echo "Found GHC $v in PATH"
        echo "Selected HIE's support: ${lib.concatStringsSep " " ghc-versions}"
        echo
    fi

    exit 1
  '';

  hie-env = pkgs.buildEnv {
    name = "hie-env";
    paths = versioned;
    pathsToLink = [ "/bin" ];
  };

  multi = pkgs.runCommandNoCCLocal "hie-multi"
    {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
    mkdir -p $out/bin
    cp ${newest}/bin/hie-wrapper $out/bin/hie
    ln -s hie $out/bin/hie-wrapper

    wrapProgram $out/bin/hie \
        --prefix PATH ":" "${lib.makeBinPath [ dummy hie-env ]}"
  '';
in
if lib.length selected == 0
then throw "You must select at least one HIE version!"
else multi
