#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage ./updateVersion.sh 3 4"
  exit 1
fi

ls opencast-* | while read line
do
  regex="s/$1/$2/"
  newname=`echo $line | sed "$regex"`
  if [ "$newname" == "$line" ]; then
    continue
  fi

  if [ -L $line ]; then
    newtarget=`readlink $line | sed "$regex"`
    ln -s $newtarget $newname
    git rm $line
    git add -f $newname
  elif [ -f $line ]; then
    git mv $line $newname
  fi
done
