#!/bin/bash

if [ $# -ne 1 ];
then
  echo "./$0 VERSION"
  exit 1
fi

version=$1
mkdir $version

profiles=( "allinone" "admin" "adminpresentation" "adminworker" "ingest" "migration" "worker" "presentation" )

for profile in "${profiles[@]}"
do
  if [ ! -f "$version/oepncast-dist-$profile-$version.tar.gz" ]; then
    fn="$version/opencast-dist-$profile-$version.tar.gz"
    wget -O $fn https://github.com/opencast/opencast/releases/download/$version/opencast-dist-$profile-$version.tar.gz
    if [[ $? -ne 0 ]]; then
      rm -rf $fn
    fi
  fi
done
