#!/bin/bash

if [ $# -ne 1 ];
then
  echo "./$0 VERSION"
  exit 1
fi

version=$1
output="octoka-$version"
mkdir -p $output
wget -O $output/octoka https://github.com/opencast/octoka/releases/download/v$version/octoka
wget -O $output/config.toml https://github.com/opencast/octoka/releases/download/v$version/config.toml
