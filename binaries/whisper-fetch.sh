#!/bin/bash

if [ $# -ne 1 ];
then
  echo "./$0 VERSION"
  exit 1
fi

version=$1
output="whisper.cpp-$version"
mkdir -p $output
wget -O $output/whisper.cpp-$version.tar.gz https://github.com/ggerganov/whisper.cpp/archive/refs/tags/v$version.tar.gz
