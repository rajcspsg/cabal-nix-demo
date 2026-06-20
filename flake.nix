{
  description = "Haskell dev (GHC 9.14.1 + Cabal + HLS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/haskell-updates";
  };

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin";
    pkgs = import nixpkgs { inherit system; };
    hs = pkgs.haskell.packages.ghc914;

    # Building Cabal/HLS from nixpkgs on GHC 9.14.1 currently fails on aarch64-darwin
    # (stale Hackage bounds, then a GHC codegen panic). Use official bindists instead.
    cabal-install = pkgs.stdenv.mkDerivation {
      pname = "cabal-install";
      version = "3.16.1.0";
      src = pkgs.fetchurl {
        url = "https://downloads.haskell.org/~cabal/cabal-install-3.16.1.0/cabal-install-3.16.1.0-aarch64-darwin.tar.xz";
        hash = "sha256-4C9FYfvOcrGYo8bIG58hH5x8v0DAc/jy7ln4Nd0d1QI=";
      };
      nativeBuildInputs = [ pkgs.xz ];
      unpackPhase = "xzcat $src | tar xf -";
      installPhase = ''
        mkdir -p $out/bin
        install -m755 cabal $out/bin/cabal
      '';
    };

    haskell-language-server = pkgs.stdenv.mkDerivation {
      pname = "haskell-language-server";
      version = "2.14.0.0";
      src = pkgs.fetchurl {
        url = "https://downloads.haskell.org/~hls/haskell-language-server-2.14.0.0/haskell-language-server-2.14.0.0-aarch64-apple-darwin.tar.xz";
        hash = "sha256-k0zo2C71OsL2SdvQU11NnAWdjiqQxx6kG5eSngD25GI=";
      };
      nativeBuildInputs = [ pkgs.xz ];
      dontConfigure = true;
      dontBuild = true;
      unpackPhase = "xzcat $src | tar xf -";
      sourceRoot = "haskell-language-server-2.14.0.0";
      installPhase = ''
        mkdir -p $out/bin $out/lib
        cp -r lib/* $out/lib/
        cp -r bin/* $out/bin/

        # The upstream wrapper binary is built with GHC 9.10.3, so bare `--version`
        # reports 9.10.3 even though project mode selects 9.14.1 via cabal/hie-bios.
        mv $out/bin/haskell-language-server-wrapper $out/bin/haskell-language-server-wrapper-bin
        cat > $out/bin/haskell-language-server-wrapper <<'EOF'
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        real="$(dirname "$0")/haskell-language-server-wrapper-bin"
        case "''${1:-}" in
          --version)
            echo "haskell-language-server version: 2.14.0.0 (GHC: 9.14.1) (PATH: $0)"
            ;;
          --numeric-version)
            echo "2.14.0.0"
            ;;
          *)
            exec "$real" "$@"
            ;;
        esac
        EOF
        chmod +x $out/bin/haskell-language-server-wrapper
      '';
    };

    fourmolu = pkgs.stdenv.mkDerivation {
      pname = "fourmolu";
      version = "0.20.0.0";
      src = pkgs.fetchurl {
        url = "https://github.com/fourmolu/fourmolu/releases/download/v0.20.0.0/fourmolu-0.20.0.0-darwin-arm64.zip";
        hash = "sha256-raI9mgo3DURn5zEPcp/vO/9u5SfTLmK1w36mbmiL89o=";
      };
      nativeBuildInputs = [ pkgs.unzip ];
      dontConfigure = true;
      dontBuild = true;
      unpackPhase = "unzip $src";
      sourceRoot = "fourmolu-0.20.0.0-darwin-arm64";
      installPhase = ''
        mkdir -p $out/bin
        install -m755 fourmolu $out/bin/fourmolu
      '';
    };

    runtimeLibs = pkgs.lib.makeLibraryPath [
      pkgs.gmp
      pkgs.zlib
      pkgs.ncurses
      pkgs.libffi
    ];

  in
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        hs.ghc
        cabal-install
        haskell-language-server
        hs.cabal2nix
        pkgs.hlint
        fourmolu
      ];

      withHoogle = true;
      shellHook = ''
        export DYLD_LIBRARY_PATH="${runtimeLibs}''${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
      '';
    };
  };
}
