#!/bin/sh

# Use together with find, for example:
# find ./ -name "*.mp3" -exec ./to-opus.sh "{}" \;

IN="$1"
OUT=${1%.*}.ogg
BITRATE=64k

echo "$IN->$OUT"

ffmpeg -y -loglevel "error" -i "$IN" -vn -acodec libopus -b:a $BITRATE "$OUT"
rm "$IN"

