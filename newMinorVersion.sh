#!/bin/bash

set -ue

if [ $# -lt 2 -o $# -gt 3 ]; then
  echo "Usage: $0 major newminor [buildnumber]"
  echo " eg: $0 4 5 -> Opencast 4.5-1"
  echo " eg: $0 4 5 44 -> Opencast 4.5-44"
  exit 1
fi

package="opencast"
build=1

#If the new flag is set, erase the current changelog
if [ $# -eq 3 ]; then
  build=$3
fi

#Regenerate the changelog, bumping to testing
./changelog.sh $1 $2 $build testing new
git add $package/debian/changelog

#Update the control file
next=`bc <<< "$1 + 1"`
cur=`bc <<< "$2 + 1"`
sed -i "s/$next.x/$1.$cur/g" $package/debian/control
sed -i "s/$1.x/$1.$2/g" $package/debian/control

git add $package/debian/control

