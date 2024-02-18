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

FFMPEG=ffmpeg

OUTPATTERN=""
INPUTFILE=""
SEGMENT_TIME="1800"

display_help() {
  echo "Usage: $0 [OPTION]... FILE"
  echo "Options:"
  echo "  -h, --help            Display this help message"
  echo "  -o, --output PATTERN  Write results to PATTERN (e.g \"out%02d.wav\")"
  echo "  -s, --split SECONDS   Split every SECONDS seconds (default: $SEGMENT_TIME)"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help ) display_help; exit ;;
    -o | --output ) OUTPATTERN="$2"; shift 2 ;;
    -* ) echo "error: unknown option $1" 1>&2; exit 1 ;;
    * )
      if [[ ! -z "${INPUTFILE}" ]]; then
        echo "error: multiple input files given" 1>&2
        exit 1
      fi

      INPUTFILE="$1"
      shift
      ;;
  esac
done

# Validate command line arguments
if [ -z "${OUTPATTERN}" ]; then
  echo "error: option --output required" 1>&2
  exit 1
fi

if [ -z "${INPUTFILE}" ]; then
  echo "error: FILE argument missing" 1>&2
  exit 1
fi

"${FFMPEG}" -i "${INPUTFILE}" -f segment -segment_time "${SEGMENT_TIME}" -start_number 1 -c copy "${OUTPATTERN}"

# EOF #
