grumedia
========

Collections of simple wrapper scripts around `ffmpeg` for manipulating
long audio files (audiobooks, podcasts, etc.) for use on MP3 player.


Usage
-----

```
usage: grumedia [-h] [-s SECONDS] [--split-at SPLITSPEC] [--split-at-chapters] [-S INDEX] [-t FACTOR] -o PATTERN [-c CODEC] [-b BITRATE] [-n] [-v] FILENAME [FILENAME ...]

Split, join or filter audiofiles

positional arguments:
  FILENAME              Input filename

options:
  -h, --help            show this help message and exit
  -s SECONDS, --split SECONDS
                        Split audio file every SECONDS seconds
  --split-at SPLITSPEC  Comma deliminated split points
  --split-at-chapters   Split at chapters
  -S INDEX, --start INDEX
                        Start output numbering at INDEX
  -t FACTOR, --tempo FACTOR
                        Speedup audio by FACTOR
  -o PATTERN, --output PATTERN
                        Write output to PATTERN
  -c CODEC, --codec CODEC
                        Output codec
  -b BITRATE, --bitrate BITRATE
                        Output codec bitrate
  -n, --dry-run         Dry run without actual conversion
  -v, --verbose         Be more verbose
```


Example
-------

Take multiple input files, concatinate them, increase their speed by
1.5x, split them every 30m and write them to mp3/01.mp3, mp3/02.mp3,
...:


```
   grumedia input1.mp3 input2.mp3 input3.mp3 -o mp3/%02d.mp3 --split 1800 --tempo 1.5
```
