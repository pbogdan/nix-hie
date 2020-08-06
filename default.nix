let
  sources = import ./nix/sources.nix;
in
{ pkgs ? import sources.unstable { }
}:
let
  inherit (pkgs.haskell.lib)
    justStaticExecutables
    overrideCabal
    ;

  inherit (pkgs)
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
              overrides = lib.composeExtensions
                (old.overrides or (_:_: { }))
                (import ./overrides/common.nix {
                  inherit pkgs lib undotted;
                }
                );
            }
          )
      ) {
      ghc-865 =
        (
          import ./hie/ghc-8.6.5.nix {
            inherit pkgs;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: { })) (
              _: _: (import ./overrides/base-8.6.x.nix)
            );
          }
        );

      ghc-882 =
        (
          import ./hie/ghc-8.8.2.nix {
            inherit pkgs;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: { })) (
              _: _: (import ./overrides/base-8.8.x.nix)
            );
          }
        );

      ghc-883 =
        (
          import ./hie/ghc-8.8.3.nix {
            inherit pkgs;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: { })) (
              _: _: (import ./overrides/base-8.8.x.nix)
            );
          }
        );

      ghc-884 =
        (
          import ./hie/ghc-8.8.4.nix {
            inherit pkgs;
          }
        ).override (
          old: {
            overrides = lib.composeExtensions (old.overrides or (_:_: { })) (
              _: _: (import ./overrides/base-8.8.x.nix)
            );
          }
        );
    };

  hies = lib.mapAttrs (_: hie-pkg-set: hie-pkg-set.haskell-ide-engine) hie-pkg-sets;

  compose = import ./compose.nix {
    inherit pkgs lib hies undotted;
  };

in
{
  hie = lib.recurseIntoAttrs hies // {
    inherit compose;
  };

  composed = compose lib.id;
}
