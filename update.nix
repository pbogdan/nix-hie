let
  sources = import ./nix/sources.nix;
in
{ pkgs ? import sources.unstable { } }:
let
  inherit (pkgs)
    mkShell
    writeShellScriptBin
    ;
  stack2nix = import sources.stack2nix { };
  script = writeShellScriptBin "update.sh" ''
    rev=$1

    for ghc in 8.6.5 8.8.2 8.8.3; do
        ${stack2nix}/bin/stack2nix \
          --revision "$1" \
          --stack-yaml stack-"$ghc".yaml \
          https://github.com/haskell/haskell-ide-engine.git > hie/ghc-"$ghc".nix
    done
  '';
in
mkShell {
  buildInputs = [
    script
  ];
}
