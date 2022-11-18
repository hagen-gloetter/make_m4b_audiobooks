#! /bin/bash

# written by hagen glötter in 2020
# contact hagen@gloetter.de

find . -name "*.flac" -exec ffmpeg -i {} -ab 160k -map_metadata 0 -id3v2_version 3 {}.mp3 \;
