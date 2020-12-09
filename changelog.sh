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

export DEBEMAIL="Greg Logan <gregorydlogan@gmail.com>"
cd opencast
#If the new flag is set, erase the current changelog
if [ $# -eq 5 ]; then
  rm -f debian/changelog
  new="--create"
else
  new="-b"
fi
#Create the changelog entry
dch \
 $new \
 --package opencast-$major \
 --newversion $major.$minor-$build \
 --allow-lower-version \
 --force-bad-version \
 -D $suite \
 -u low \
 "Initial release based on Opencast $major.$minor"
#Zero out the time
sed -i 's/..\:..\:../00:00:00/' debian/changelog
sed -i "s/\(opencast.*\) $major.[x0-9]\{1,2\}-[x0-9]\{1,2\}/\1 $major.$minor-$build/g" debian/control
