{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3Packages;
      in rec {
        packages = rec {
          default = grumedia-all;

          grumedia-all = pkgs.buildEnv {
            name = "grumedia-all";
            paths = [ grumedia youtube2mp3 ];
          };

          grumedia = pythonPackages.buildPythonPackage rec {
            pname = "grumedia";
            version = "0.0.0";
            format = "pyproject";
            src = ./.;

            buildInputs = with pythonPackages; [
              setuptools
            ];
          };

          youtube2mp3 = pkgs.stdenv.mkDerivation rec {
            pname = "youtube2mp3";
            version = "0.0.0";

            src = ./.;

            installPhase = ''
              mkdir -p $out/bin
              for i in *.sh; do
                install "$i" "$out/bin/grumedia-''${i%%.sh}"
                substituteInPlace "$out/bin/grumedia-''${i%%.sh}" \
                  --replace "FFMPEG=ffmpeg" "FFMPEG='${pkgs.ffmpeg}/bin/ffmpeg'" \
                  --replace "YTDLP=yt-dlp"  "YTDLP='${pkgs.yt-dlp}/bin/yt-dlp'" \
                  --replace "GETOPT=getopt"  "GETOPT='${pkgs.getopt}/bin/getopt'"
              done
            '';
          };
        };

        apps = rec {
          default = grumedia;

          grumedia = flake-utils.lib.mkApp {
            drv = packages.grumedia;
            exePath = "/bin/grumedia";
          };

          youtube2mp3 = flake-utils.lib.mkApp {
            drv = packages.youtube2mp3;
            exePath = "/bin/grumedia-youtube2mp3";
          };
        };
      }
    );
}
