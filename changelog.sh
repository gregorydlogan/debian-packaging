#!/bin/bash

if [ $# -lt 3 -o $# -gt 4 ]; then
  echo "Usage: updateVersion.sh package version suite [new]"
  echo " eg: updateVersion.sh opencast 3.4-1 testing -> set Opencast's version to 3.4-1 in testing"
    echo " eg: updateVersion.sh opencast 4.0-1 testing new -> erase the current changelog for opencast and do the above"
  exit 1
fi

package=$1
version=$2
suite=$3

export DEBEMAIL="Greg Logan <gregorydlogan@gmail.com>"
cd $package
#If the new flag is set, erase the current changelog
if [ $# -eq 4 ]; then
  rm -f debian/changelog
  new="--create"
fi
#Create the changelog entry
dch \
 $new \
 --package $package \
 --newversion $version \
 -D $suite \
 -u low \
 "Initial release of Debian packages based on Opencast $2.x"
#Zero out the time
sed -i 's/..\:..\:../00:00:00/' debian/changelog
