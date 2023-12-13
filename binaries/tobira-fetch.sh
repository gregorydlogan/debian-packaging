#!/bin/bash

if [ $# -ne 1 ];
then
  echo "./$0 VERSION"
  exit 1
fi

version=$1
output="tobira-$version"
mkdir -p $output
wget -O $output/tobira https://github.com/elan-ev/tobira/releases/download/v$version/tobira-x86_64-unknown-linux-gnu
wget -O $output/config.toml https://github.com/elan-ev/tobira/releases/download/v$version/config.toml
