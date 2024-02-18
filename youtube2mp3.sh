#!/bin/sh
YTDLP=yt-dlp
exec "${YTDLP}" --extract-audio --audio-format mp3 --audio-quality 0 --output "%(title)s.%(ext)s" "$@"
# EOF #
