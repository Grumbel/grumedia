#!/usr/bin/env bash

set -e

FFMPEG=ffmpeg

OUTPATTERN=""
INPUTFILE=""
SEGMENT_TIME="1800"

display_help() {
  echo "Usage: $0 [OPTION]... FILE"
  echo "Options:"
  echo "  -h, --help            Display this help message"
  echo "  -o, --output PATTERN  Write results to PATTERN"
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
