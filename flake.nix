{
  description = "Haskell development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };

    hs = pkgs.haskell.packages.ghc914;
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      

      buildInputs =  [
        hs.ghc
        pkgs.cabal-install
        pkgs.cabal2nix
        pkgs.haskell-language-server
        pkgs.hlint
        pkgs.fourmolu
      ];

      withHoogle = true;
    };
  };
}
