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
import json
import multiprocessing
import os
import shlex
import subprocess
import sys
import tempfile
import time

from typing import Optional


def parse_args(args: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog='grumedia', description='Split, join or filter audiofiles')
    parser.add_argument('FILENAME', nargs='+',
                        help="Input filename")
    parser.add_argument('-s', '--split', type=int, metavar="SECONDS", default=None,
                        help="Split audio file every SECONDS seconds")
    parser.add_argument('--split-at', type=str, metavar="SPLITSPEC", default=None,
                        help="Comma deliminated split points")
    parser.add_argument('--split-at-chapters', action='store_true', default=False,
                        help="Split at chapters")
    parser.add_argument('-S', '--start', type=int, metavar="INDEX", default=1,
                        help="Start output numbering at INDEX")
    parser.add_argument('-t', '--tempo', type=float, metavar="FACTOR", default=1.0,
                        help="Speedup audio by FACTOR")
    parser.add_argument('-o', '--output', type=str, metavar="PATTERN", required=True,
                        help="Write output to PATTERN")
    parser.add_argument('-c', '--codec', type=str, default=None,
                        help="Output codec")
    parser.add_argument('-b', '--bitrate', type=str, default="64k",
                        help="Output codec bitrate")
    parser.add_argument('-n', '--dry-run', action='store_true',
                        help="Dry run without actual conversion")
    parser.add_argument('-v', '--verbose', action='store_true',
                        help="Be more verbose")
    return parser.parse_args(args)


def ffmpeg_quote(text: str):
    return shlex.quote(text)


def segments_from_chapters(filename: str) -> list[tuple[float, float]]:
    segments = []
    proc = subprocess.Popen(["ffprobe", "-loglevel", "quiet", "-print_format", "json", "-show_chapters", filename],
                            stdout=subprocess.PIPE)
    outs, errs = proc.communicate()
    js = json.loads(outs)

    segments = []
    for chapter_js in js["chapters"]:
        # title = chapters_js["tags"]["title"]
        segments.append((chapter_js["start_time"],
                         chapter_js["end_time"]))
    return segments


def parse_segments(text: str) -> list[float]:
    pos_list = text.split(",")
    return [(pos_list[x], pos_list[x + 1]) for x in range(len(pos_list) - 1)] + [(pos_list[-1], None)]


def build_ffmpeg_input_args_list(opts: argparse.Namespace) -> list[list[str]]:
    if opts.split_at_chapters:
        if len(opts.FILENAME) != 1:
            raise RuntimeError("only one input file allowed for --split-at-chapters")
        segments = segments_from_chapters(opts.FILENAME[0])
    elif opts.split_at is not None:
        segments = parse_segments(opts.split_at)
    else:
        segments = None

    ffmpeg_args = []

    if len(opts.FILENAME) == 1:
        ffmpeg_args += ["-i", opts.FILENAME[0]]
    else:
        fout = tempfile.NamedTemporaryFile(mode='w', encoding="UTF-8",
                                           prefix="grumedia_",
                                           delete=False
                                           )
        for filename in opts.FILENAME:
            fout.write("file {:s}\n".format(ffmpeg_quote(os.path.abspath(filename))))
        fout.flush()

        ffmpeg_args += ["-safe", "0",
                        "-f", "concat", "-i", fout.name]

    # select only the audio stream
    ffmpeg_args += ["-map", "0:a"]

    ffmpeg_args_list = []
    if segments is None:
        ffmpeg_args_list.append(ffmpeg_args)
    else:
        for start, end in segments:
            segment_args = ["-ss", start]
            if end is not None:
                segment_args += ["-to", end]
            ffmpeg_args_list.append(segment_args + ffmpeg_args)

    return ffmpeg_args_list


def build_ffmpeg_filter_args(opts: argparse.Namespace) -> list[str]:
    ffmpeg_args = []

    # tempo flags
    if opts.tempo != 1.0:
        ffmpeg_args += ["-filter:a", f"atempo={opts.tempo}"]

    return ffmpeg_args


def build_ffmpeg_output_args(opts: argparse.Namespace, idx: Optional[int]) -> list[str]:
    ffmpeg_args = []

    # split flags
    if opts.split is not None:
        ffmpeg_args += ["-f", "segment",
                        "-segment_time", f"{opts.split}",
                        "-segment_start_number", f"{opts.start}",
                        "-reset_timestamps", "1"]

    if opts.codec is not None:
        ffmpeg_args += ["-codec:a", f"{opts.codec}"]

    if opts.bitrate is not None:
        ffmpeg_args += ["-b:a", f"{opts.bitrate}"]

    # output flags
    if idx is not None:
        ffmpeg_args += [f"{opts.output.format(idx)}"]
    else:
        ffmpeg_args += [f"{opts.output}"]

    return ffmpeg_args


def call_ffmpeg(args: list[str],
                opts: argparse.Namespace) -> None:
    if opts.verbose:
        print(f"fmpeg arguments: {args}")

    if not opts.dry_run:
        subprocess.check_call(["ffmpeg"] + args)


def task_processor(args):
    call_ffmpeg(*args)


def main(argv: list[str]) -> None:
    opts = parse_args(argv[1:])

    target_directory = os.path.dirname(opts.output)
    if target_directory != "":
        if  not os.path.isdir(target_directory):
            os.mkdir(target_directory)

    default_args = ["-nostdin"]
    input_args_list = build_ffmpeg_input_args_list(opts)
    filter_args = build_ffmpeg_filter_args(opts)
    verbose_args = [] if opts.verbose else ["-loglevel", "quiet"]

    task_args_list = []
    for idx, input_args in enumerate(input_args_list):
        output_args = build_ffmpeg_output_args(opts, idx)
        task_args_list += [(default_args + verbose_args + input_args + filter_args + output_args, opts)]

    with multiprocessing.Pool() as pool:
        pool.map(task_processor, task_args_list)


def main_entrypoint() -> None:
    main(sys.argv)


if __name__ == "__main__":
    main_entrypoint()


# EOF #
