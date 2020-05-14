let
  sources = import ./nix/sources.nix;

  # 20.03 with GHC 8.6.5 as default and with glibc 2.30
  stable = import sources.stable {};

  # nixos-unstable with GHC 8.8.3 as default and with glibc 2.30
  unstable = import sources.unstable {};

  inherit (unstable.haskell.lib)
    justStaticExecutables
    overrideCabal
    ;
  inherit (unstable)
    fetchFromGitHub
    lib
    remove-references-to
    ;

  undotted = x: lib.replaceChars [ "." ] [ "" ] x;

  # We need to explicitly disable GHC core libraries here. stack2nix does null some of them out but
  # has not been updated for newer GHC versions so few of them are missing. The lists of the core
  # libraries are taken directly from configuration-ghc-8.x.x.nix files from nixpkgs.

  hie-pkg-sets =
    lib.mapAttrs
      (
        _: pkg-set:
          pkg-set.override (
            old: {
              # common overrides applicable to all sets
              overrides = lib.composeExtensions (old.overrides or (_:_: {})) (
                hself: hsuper: {
                  mkDerivation = args: hsuper.mkDerivation (
                    args // {
                      enableLibraryProfiling = false;
                      doHaddock = false;
                    }
                  );

                  cabal-helper = overrideCabal
                    hsuper.cabal-helper
                    (
                      drv: {
                        src = fetchFromGitHub {
                          owner = "pbogdan";
                          repo = "cabal-helper";
                          rev = "d6db50a335b69f8d1ddbebbbfba3abcbb3facdfe";
                          sha256 = "1y4scdxs7hfm0igwfx4fiiricmjaxhlfxx03v3zh557kgq9hvkx7";
                        };
                      }
                    );

                  haskell-ide-engine = justStaticExecutables
                    (
                      overrideCabal
                        hsuper.haskell-ide-engine
                        (
                          drv: {
                            pname = "hie-ghc${undotted hself.ghc.version}";

                            postInstall = drv.postInstall or "" + ''
                              remove-references-to -t ${hself.ghc} $out/bin/hie{,-wrapper}
                            '';
                          }
                        )
                    );
                }
              );
            }
          )
      )
      {
        ghc-865 = (
          import ./hie/ghc-8.6.5.nix {
            pkgs = stable;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: {})) (
              hself: hsuper: {
                # Disable GHC 8.6.x core libraries.
                array = null;
                base = null;
                binary = null;
                bytestring = null;
                Cabal = null;
                containers = null;
                deepseq = null;
                directory = null;
                filepath = null;
                ghc-boot = null;
                ghc-boot-th = null;
                ghc-compact = null;
                ghc-heap = null;
                ghc-prim = null;
                ghci = null;
                haskeline = null;
                hpc = null;
                integer-gmp = null;
                libiserv = null;
                mtl = null;
                parsec = null;
                pretty = null;
                process = null;
                rts = null;
                stm = null;
                template-haskell = null;
                terminfo = null;
                text = null;
                time = null;
                transformers = null;
                unix = null;
                xhtml = null;
              }
            );
          }
        );

        ghc-882 = (
          import ./hie/ghc-8.8.2.nix {
            pkgs = unstable;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: {})) (
              hself: hsuper: {
                # Disable GHC 8.8.x core libraries.
                array = null;
                base = null;
                binary = null;
                bytestring = null;
                Cabal = null;
                containers = null;
                deepseq = null;
                directory = null;
                filepath = null;
                ghc-boot = null;
                ghc-boot-th = null;
                ghc-compact = null;
                ghc-heap = null;
                ghc-prim = null;
                ghci = null;
                haskeline = null;
                hpc = null;
                integer-gmp = null;
                libiserv = null;
                mtl = null;
                parsec = null;
                pretty = null;
                process = null;
                rts = null;
                stm = null;
                template-haskell = null;
                terminfo = null;
                text = null;
                time = null;
                transformers = null;
                unix = null;
                xhtml = null;
              }
            );
          }
        );

        ghc-883 = (
          import ./hie/ghc-8.8.3.nix {
            pkgs = unstable;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: {})) (
              hself: hsuper: {
                # Disable GHC 8.8.x core libraries.
                array = null;
                base = null;
                binary = null;
                bytestring = null;
                Cabal = null;
                containers = null;
                deepseq = null;
                directory = null;
                filepath = null;
                ghc-boot = null;
                ghc-boot-th = null;
                ghc-compact = null;
                ghc-heap = null;
                ghc-prim = null;
                ghci = null;
                haskeline = null;
                hpc = null;
                integer-gmp = null;
                libiserv = null;
                mtl = null;
                parsec = null;
                pretty = null;
                process = null;
                rts = null;
                stm = null;
                template-haskell = null;
                terminfo = null;
                text = null;
                time = null;
                transformers = null;
                unix = null;
                xhtml = null;
              }
            );
          }
        );
      };

  hies = lib.mapAttrs (_: hie-pkg-set: hie-pkg-set.haskell-ide-engine) hie-pkg-sets;

  compose = selector:
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
              drv = lib.addMetaAttrs { inherit priority; } (
                unstable.runCommandNoCC hie.name {} ''
                  mkdir -p $out/bin
                  ln -s ${hie}/bin/hie $out/bin/hie-${v}
                  ln -s ${hie}/bin/hie $out/bin/hie-${v-mm}
                ''
              );
            in drv
        ) selected;

      newest = lib.head (
        lib.sort
          (a: b: builtins.compareVersions a.compiler.version b.compiler.version > -1)
          selected
      );

      dummy = unstable.writeShellScriptBin "hie" ''
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

      hie-env = unstable.buildEnv {
        name = "hie-env";
        paths = versioned;
        pathsToLink = [ "/bin" ];
      };

      multi = unstable.runCommandNoCC "hie-multi" {
        nativeBuildInputs = [ unstable.makeWrapper ];
      } ''
        mkdir -p $out/bin
        cp ${newest}/bin/hie-wrapper $out/bin/hie
        ln -s hie $out/bin/hie-wrapper

        wrapProgram $out/bin/hie \
            --prefix PATH ":" "${lib.makeBinPath [ dummy hie-env ]}"
      '';
    in if lib.length selected == 0
    then throw "You must select at least one HIE version!"
    else multi;
in
{
  hie = lib.recurseIntoAttrs hies // {
    inherit compose;
  };
}
