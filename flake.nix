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
    devShells.${system}.default = hs.shellFor {
      packages = p: [];

      buildInputs = with pkgs; [
        hs.cabal-install
        hs.cabal2nix
        hs.haskell-language-server
        hs.hlint
        hs.fourmolu
      ];

      withHoogle = true;
    };
  };
}
