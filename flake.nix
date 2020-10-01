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
    nixpkgs.lib.recursiveUpdate
      (flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          inherit (import ./default.nix {
            inherit pkgs;
          })
            hie
            ;
        in
        {
          packages = flake-utils.lib.flattenTree hie;

          defaultPackage = hie.compose nixpkgs.lib.id;

          lib = {
            inherit (hie)
              compose
              ;
          };
        }))
      {
        overlay = final: prev: {
          inherit (import ./default.nix {
            pkgs = final;
          })
            hie
            ;
        };
      };
}
