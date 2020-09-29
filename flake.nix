{
  description = "Haskell IDE Engine for Nix";

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        hie = import ./default.nix {
          inherit pkgs;
        };
      in
      {
        packages = flake-utils.lib.flattenTree hie;

        defaultPackage = self.packages.x86_64-linux.composed;

        lib = {
          inherit (hie)
            compose
            ;
        };
      });
}
