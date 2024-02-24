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
FFMPEG=ffmpeg

INPUTFILE=""
OUTFILE=""
TEMPO=1
REST=()

display_help() {
  echo "Usage: $0 [OPTION]... FILE"
  echo "Options:"
  echo "  -h, --help          Display this help message"
  echo "  -o, --output FILE   Write results to FILE"
  echo "  -t, --tempo TEMPO   Change audio speed by factor TEMPO"
}

# Parse command line arguments
opts=$("${GETOPT}" --name "$0" --options ho:t: --longoptions help,output:,tempo: -- "$@")
eval set -- "$opts"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help ) display_help; exit ;;
    -o | --output ) OUTFILE="$2"; shift 2 ;;
    -t | --tempo ) TEMPO="$2"; shift 2 ;;
    -- ) shift; break ;;
  esac
done

# Validate command line arguments
if [[ $# -gt 1 ]]; then
  echo "error: FILE argument missing" 1>&2
  exit 1
else
  INPUTFILE="$1"
fi

if [[ -z "$OUTFILE" ]]; then
  echo "error: option --output required" 1>&2
  exit 1
fi

"${FFMPEG}" -i "${INPUTFILE}" -filter:a "atempo=${TEMPO}" -vn -b:a 128K -vn "${OUTFILE}"

# EOF #