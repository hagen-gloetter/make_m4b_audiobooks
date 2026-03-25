#! /bin/bash

# written by hagen glötter in 2020
# contact hagen@gloetter.de

for i in *.mp3 ; do ffmpeg -i  "$i" -c:a aac -strict experimental -b:a 128k -f mp4 "$i.m4b" ; done
