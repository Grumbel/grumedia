#!/usr/bin/env bash

set -e

FFMPEG=ffmpeg

display_help() {
  echo "Usage: $0 [OPTION]... FILE..."
  echo "Options:"
  echo "  -h, --help          Display this help message"
  echo "  -o, --output FILE   Write results to FILE"
}

# Parse command line arguments
OUTFILE=""
REST=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help ) display_help; exit ;;
    -o | --output ) OUTFILE="$2"; shift 2 ;;
    -* ) echo "error: unknown option $1" 1>&2; exit 1 ;;
    * ) REST+=("$1"); shift ;;
  esac
done

# Validate command line arguments
if [ -z "$OUTFILE" ]; then
  echo "error: option --output required" 1>&2
  exit 1
fi

if [ ! ${#REST[@]} -gt 0 ]; then
  echo "error: FILE argument missing" 1>&2
  exit 1
fi

# Generate file list
FILELIST=$(for i in "${REST[@]}"; do
  printf "file %q\n" "$(realpath "$i")"
done)

# Run conversion
"${FFMPEG}" -safe 0 -f concat -i <(echo "${FILELIST}") -b:a 128K -vn "${OUTFILE}"
echo "Wrote ${OUTFILE}"

# EOF #
