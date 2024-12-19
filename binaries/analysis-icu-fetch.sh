#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 \$VERSION"
  echo " eg: $0 1.3.16    -> Downloads analysis-icu 1.3.16 from Maven Central"
  exit 1
fi

if [ ! -f "analysis-icu-$1.zip" ]; then
  wget https://artifacts.opensearch.org/releases/plugins/analysis-icu/$1/analysis-icu-$1.zip
fi
