#!/bin/bash

if [ $# -ne 3 ]
then
  echo "Usage: updateVersion.sh version suite"
  echo " eg: updateVersion.sh 3.4-1 testing"
  exit 1
fi

if [ ! -d $1 ]
then
  echo "Directory $1 does not exist"
  exit 1
fi

version=`echo $2 | cut -f 1 -d "-"`
export DEBFULLNAME="Greg Logan"
export DEBEMAIL="gregorydlogan@gmail.com"

cd $1
dch --newversion $2 -b -D $3 -u low --empty "Initial release of Debian packages based on Opencast $version"
cd ..
