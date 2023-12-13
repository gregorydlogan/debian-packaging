#!/bin/bash

VERSION="release"
ARCH="amd64"

if [ $# -ge 3 ]; then
  echo "Usage: $0 [release=$VERSION] [arch=$ARCH]"
  echo " eg: $0           -> Downloads ffmpeg-release-amd64-static.tar.xz"
  echo " eg: $0 6.0       -> Downloads ffmpeg-6.0-amd64-static.tar.xz"
  echo " eg: $0 6.0 arm64 -> Downloads ffmpeg-6.0-arm64-static.tar.xz"
  exit 1
fi


if [ $# -ge 1 ]; then
  VERSION="$1"
fi
if [ $# -ge 2 ]; then
  ARCH="$2"
fi

wget https://s3.opencast.org/opencast-ffmpeg-static/ffmpeg-$VERSION-$ARCH-static.tar.xz
