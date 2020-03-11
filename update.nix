with  import (
  fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/acbdaa569f4ee387386ebe1b9e60b9f95b4ab21b";
    sha256 = "0xzyghyxk3hwhicgdbi8yv8b8ijy1rgdsj5wb26y5j322v96zlpz";
  }
) {};
let
  script = writeScriptBin "update.sh" ''
    #!${pkgs.runtimeShell}

    rev=$1

    for ghc in 8.6.5 8.8.2; do
        ${pkgs.stack2nix}/bin/stack2nix \
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
