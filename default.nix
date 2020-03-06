let
  sources = import ./nix/sources.nix;

  # 20.03 with GHC 8.6.5 as default and with glibc 2.30
  stable = import sources.stable {};

  # nixpkgs-unstable with GHC 8.8.2 as default and with glibc 2.30
  unstable = import sources.unstable {};

  # We need to explicitly disable GHC core libraries here. stack2nix does null some of them out but
  # has not been updated for newer GHC versions so few of them are missing. These are directly taken
  # from configuration-ghc-8.x.x.nix files from nixpkgs.
  hie-ghc-865 = (
    import ./hie/ghc-8.6.5.nix {
      pkgs = stable;
    }
  ).override {
    overrides = hself: hsuper: {
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

      mkDerivation = args: hsuper.mkDerivation (
        args // {
          enableLibraryProfiling = false;
          doHaddock = false;
        }
      );
    };
  };

  hie-ghc-882 = (
    import ./hie/ghc-8.8.2.nix {
      pkgs = unstable;
    }
  ).override {
    overrides = hself: hsuper: {
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

      mkDerivation = args: hsuper.mkDerivation (
        args // {
          enableLibraryProfiling = false;
          doHaddock = false;
        }
      );
    };
  };

  inherit (stable.haskell.lib) justStaticExecutables;
in
{
  hie = {
    ghc865 = justStaticExecutables hie-ghc-865.haskell-ide-engine;
    ghc882 = justStaticExecutables hie-ghc-882.haskell-ide-engine;
  };
}
