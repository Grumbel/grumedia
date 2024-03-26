#!/usr/bin/env python3

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


import argparse
import io
import os
import shlex
import subprocess
import sys
import tempfile
import time


def parse_args(args: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog='grumedia', description='Split, join or filter audiofiles')
    parser.add_argument('FILENAME', nargs='+',
                        help="Input filename")
    parser.add_argument('-s', '--split', type=int, metavar="SECONDS", default=None,
                        help="Split audio file every SECONDS seconds")
    parser.add_argument('-S', '--start', type=int, metavar="INDEX", default=1,
                        help="Start output numbering at INDEX")
    parser.add_argument('-t', '--tempo', type=float, metavar="FACTOR", default=1.0,
                        help="Speedup audio by FACTOR")
    parser.add_argument('-o', '--output', type=str, metavar="PATTERN", required=True,
                        help="Write output to PATTERN")
    parser.add_argument('-e', '--encoding', type=str, default=None,
                        help="Output encoding")
    parser.add_argument('-n', '--dry-run', action='store_true',
                        help="Dry run without actual conversion")
    parser.add_argument('-v', '--verbose', action='store_true',
                        help="Be more verbose")
    return parser.parse_args(args)


def ffmpeg_quote(text: str):
    return shlex.quote(text)


def build_ffmpeg_args(opts: argparse.Namespace):
    ffmpeg_args = []

    # input flags
    if len(opts.FILENAME) == 1:
        ffmpeg_args += ["-i", opts.FILENAME[0]]
    else:
        fout = tempfile.NamedTemporaryFile(mode='w', encoding="UTF-8",
                                           prefix="grumedia_",
                                           # delete_on_close=False
                                           )
        for filename in opts.FILENAME:
            fout.write("file {:s}\n".format(ffmpeg_quote(filename)))
        fout.flush()

        ffmpeg_args += ["-safe", "0",
                        "-f", "concat", "-i", fout.name,
                        # select only the audio stream
                        "-map", "0:a"]

    # tempo flags
    if opts.tempo != 1.0:
        ffmpeg_args += ["-filter:a", f"atempo={opts.tempo}"]

    # split flags
    if opts.split is not None:
        ffmpeg_args += ["-f", "segment",
                        "-segment_time", f"{opts.split}",
                        "-segment_start_number", f"{opts.start}",
                        "-reset_timestamps", "1"]

    if opts.encoding is None:
        ffmpeg_args += ["-b:a", "128K"]
    elif opts.encoding == "copy":
        ffmpeg_args += ["-c", "copy"]
    else:
        ffmpeg_args += ["-b:a", opts.encoding]

    # output flags
    ffmpeg_args += [f"{opts.output}"]

    return ffmpeg_args


def main(argv: list[str]) -> None:
    opts = parse_args(argv[1:])
    ffmpeg_args = build_ffmpeg_args(opts)

    if opts.verbose:
        print(ffmpeg_args)

    if not opts.dry_run:
        subprocess.check_call(["ffmpeg"] + ffmpeg_args)


def main_entrypoint() -> None:
    main(sys.argv)


if __name__ == "__main__":
    main_entrypoint()


# EOF #
