{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = rec {
          default = grumedia;

          grumedia = pkgs.stdenv.mkDerivation rec {
            pname = "grumedia";
            version = "0.0.0";

            src = ./.;

            installPhase = ''
              mkdir -p $out/bin
              for i in *.sh; do
                install "$i" "$out/bin/''${i%%.sh}"
                substituteInPlace "$out/bin/''${i%%.sh}" \
                  --replace "FFMPEG=ffmpeg" "FFMPEG='${pkgs.ffmpeg}/bin/ffmpeg'"
              done
            '';
          };
        };

        apps = rec {
          default = grumedia-audio-cat;

          grumedia-audio-cat = flake-utils.lib.mkApp {
            drv = packages.grumedia;
            exePath = "/bin/grumedia-audio-cat";
          };
        };
      }
    );
}
