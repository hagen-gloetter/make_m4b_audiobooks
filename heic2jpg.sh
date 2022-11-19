#! /bin/bash

for f in *.HEIC; do heif-convert -q 100 $f $f.jpg; done
#find . -iname "*.heic" -exec heif-convert -q 100 {} {}.jpg \;
