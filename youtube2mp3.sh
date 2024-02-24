#!/usr/bin/env bash

# grumedia
# Copyright (C) 2024 Ingo Ruhnke <grumbel@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

GETOPT=getopt
YTDLP=yt-dlp

AUDIO_FORMAT=mp3
AUDIO_QUALITY=5
OUTPUT_FORMAT="%(title)s.%(ext)s"
URLS=()

display_help() {
  echo "Usage: $0 [OPTION]... URL..."
  echo "Options:"
  echo "  -h, --help            Display this help message"
  echo "  -o, --output PATTERN  Write results to PATTERN (default: ${OUTPUT_FORMAT}"
  echo "  -q, --quality NUM     Audio quality (default: ${AUDIO_QUALITY})"
  echo "  -f, --format FMT      Audio format (default: ${AUDIO_FORMAT})"
}

opts=$("${GETOPT}" --name "$0" --options ho:q:f: --longoptions help,output:,quality:,format: -- "$@")
eval set -- "$opts"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help ) display_help; exit ;;
    -o | --output ) OUTPUT_FORMAT="$2"; shift 2 ;;
    -q | --quality ) AUDIO_QUALITY="$2"; shift 2 ;;
    -f | --format ) AUDIO_FORMAT="$2"; shift 2 ;;
    -- ) shift; URLS=("$@"); break ;;
  esac
done

# Validate command line arguments
if [ -z "${OUTPUT_FORMAT}" ]; then
  echo "error: option --output required" 1>&2
  exit 1
fi

if [ ! "${#URLS[@]}" -gt 0 ]; then
  echo "error: URL argument missing" 1>&2
  exit 1
fi

exec "${YTDLP}" \
     --extract-audio \
     --audio-format "${AUDIO_FORMAT}" \
     --audio-quality "${AUDIO_QUALITY}" \
     --output "${OUTPUT_FORMAT}" \
     "${URLS}"

# EOF #
