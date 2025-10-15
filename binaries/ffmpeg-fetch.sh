#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 slug"
  echo " eg: $0 n7.1.1-54-g6400860b9d -> Downloads ffmpeg-n7.1.1-54-g6400860b9d-linux64-gpl-7.1.tar.xz and ffmpeg-n7.1.1-54-g6400860b9d-linuxarm64-gpl-7.1.tar.xz"
  exit 1
fi


if [ $# -ge 1 ]; then
  SLUG="$1"
  SUBSLUG="${SLUG:1:3}"
fi

wget https://s3.opencast.org/opencast-ffmpeg-static/ffmpeg-$SLUG-linux64-gpl-$SUBSLUG.tar.xz
wget https://s3.opencast.org/opencast-ffmpeg-static/ffmpeg-$SLUG-linuxarm64-gpl-$SUBSLUG.tar.xz
