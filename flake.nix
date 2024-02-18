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
                install "$i" "$out/bin/grumedia-''${i%%.sh}"
                substituteInPlace "$out/bin/grumedia-''${i%%.sh}" \
                  --replace "FFMPEG=ffmpeg" "FFMPEG='${pkgs.ffmpeg}/bin/ffmpeg'" \
                  --replace "YTDLP=yt-dlp"  "YTDLP='${pkgs.yt-dlp}/bin/yt-dlp'"
              done
            '';
          };
        };

        apps = rec {
          default = audio-join;

          audio-join = flake-utils.lib.mkApp {
            drv = packages.grumedia;
            exePath = "/bin/grumedia-audio-join";
          };

          youtube2mp3 = flake-utils.lib.mkApp {
            drv = packages.grumedia;
            exePath = "/bin/grumedia-youtube2mp3";
          };
        };
      }
    );
}
