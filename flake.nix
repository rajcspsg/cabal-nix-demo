{
  description = "Haskell dev (GHC + NIX aligned)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    hs = pkgs.haskell.packages.ghc914;

    hls = hs.haskell-language-server; 
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        hs.ghc
        pkgs.cabal-install
        pkgs.cabal2nix

        hls   

        pkgs.hlint
        pkgs.fourmolu
      ];
    };
  };
}
