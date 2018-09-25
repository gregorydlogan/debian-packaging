#!/bin/bash

set -ue

if [ $# -ne 2 ]; then
  echo "Usage: $0 oldversion newversion"
  echo " eg: $0 6 7"
  exit 1
fi

package="opencast"

#Regenerate the changelog
./changelog opencast $2.x-1 unstable
git add $package/debian/changelog

#Update the control file
sed -i "s/$1.x/$2.x/g" $package/debian/control
sed -i "s/$package-$1/$package-$2/g" $package/debian/control

git add $package/debian/changelog $package/debian/control

#For all the packaging instruction files
ls opencast/debian/opencast-$1* | while read line
do
  newname=`echo $line | sed "s/opencast-$1/opencast-$2/"`
  #We do links first since links are a subset of files
  if [ -L "$line" ]; then
    #If it's a symlink, figure out where it should be linking to, remove the old one, and create a new one
    git rm $line
    allname=`echo $newname | sed "s/$2-.*.p/$2-all.p/" | sed "s/opencast\/debian\///"`
    ln -s $allname $newname
    git add -f $newname
  elif [ -f "$line" ]; then
    #If it's a plain file, rename it
    git mv $line $newname
  fi
done
