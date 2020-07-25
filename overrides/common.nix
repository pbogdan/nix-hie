{ pkgs, lib, undotted }:
let
  inherit (pkgs.haskell.lib)
    overrideCabal
    justStaticExecutables
    ;
  inherit (pkgs)
    fetchFromGitHub
    ;
in
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

  haskell-ide-engine = justStaticExecutables (
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
