#!/bin/bash

if [ $# -lt 4 -o $# -gt 5 ]; then
  echo "Usage: updateVersion.sh major minor build suite [new]"
  echo " eg: updateVersion.sh 3 4 1 testing -> set Opencast's version to 3.4-1 in testing"
    echo " eg: updateVersion.sh 4 0 1 testing new -> erase the current changelog for opencast and set the version to 4.0-1 in testing"
  exit 1
fi

major=$1
minor=$2
build=$3
suite=$4

#If the new flag is set, erase the current changelog
if [ $# -eq 5 ]; then
  ./changelog.sh $1 $2 $3 $4 new
else
  ./changelog.sh $1 $2 $3 $4
fi
git tag -sm "Opencast $1.$2-$3" $1.$2-$3
