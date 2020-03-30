let
  sources = import ./nix/sources.nix;

  # 20.03 with GHC 8.6.5 as default and with glibc 2.30
  stable = import sources.stable {};

  # nixpkgs-unstable with GHC 8.8.2 as default and with glibc 2.30
  unstable = import sources.unstable {};

  inherit (unstable.haskell.lib)
    justStaticExecutables
    overrideCabal
    ;
  inherit (unstable)
    lib
    remove-references-to
    ;

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

                  haskell-ide-engine = justStaticExecutables
                    (
                      overrideCabal
                        hsuper.haskell-ide-engine
                        (
                          drv: {
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
in
{
  hie = lib.recurseIntoAttrs (
    lib.genAttrs [ "ghc-865" "ghc-882" "ghc-883" ] (name: hie-pkg-sets.${name}.haskell-ide-engine)
  );
}
