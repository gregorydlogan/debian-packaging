#!/bin/bash

set -e

#Usage: doBuild directoryname
#eg: doBuild opencast
doBuild() {
  cd $1
  echo "Building $1"
  dpkg-buildpackage -k3259FFB3967266533FCD4B249A7EA8E5B3820B26 -tc
  cd ..
}


#Usage: createOutputs hash branchname friendlyname, falls back to using branch name if friendly is missing
#eg: createOutputs <some git has> r/3.2 3.2-new
createOutputs() {
  mkdir -p outputs/$1
  if [ $# -eq 3 ]; then
    if [ ! -h outputs/$3 ]; then
      ln -s $1 outputs/$3
    fi
  else
    if [ ! -h outputs/$2 ]; then
      ln -s $1 outputs/$2
    fi
  fi
}


#Usage: doOpencast packageversion branchname friendlyname
#eg: doOpencast 3.1 r/3.1 3.1-new
doOpencast() {

  git checkout $2

  VERSION=`git rev-parse HEAD`

  echo "Building $VERSION as $2"

  echo "Cleaning up prior to build start"
  mkdir -p opencast/build
  rm -rf opencast/build/*

  echo "Linking binaries for initial processing"
  ls binaries/$1 | while read line
  do
    ln binaries/$1/$line opencast/build/$line
  done

  echo "Extracting common files and build profiles"
  cd opencast
  #This needs to be here since the tar line(s) below does not create it
  mkdir -p build/opencast-dist-base
  ls build | grep -v "opencast-dist-base" | while read line
  do
    echo -e "\nProcessing $line"
    #Determine what the *internal* directory name is inside the individual tarballs
    archiveName=`echo $line | sed 's/-SNAPSHOT//' | rev | cut -d '-' -f 2- | rev`
    #Extract *just* the profiles
    echo "Extracting Karaf feature config"
    tar -xvf build/$line -C build $archiveName/etc/org.apache.karaf.features.cfg
    tar -xvf build/$line -C build $archiveName/etc/profile.cfg
    #Extract the contents of the various tarballs to the common base
    echo "Extracting contents to common base directory"
    tar --strip-components=1 -xf build/$line -C build/opencast-dist-base
    rm -f build/$line
  done
  echo ""
  #Remove the karaf feature configuration file, since that is set with the packages
  rm -f build/opencast-dist-base/etc/org.apache.karaf.features.cfg
  rm -f build/opencast-dist-base/etc/profile.cfg
  cd ..

  echo "Building source tarball"
  #Exclude the raw tarballs
  majorVersion=`echo $1 | cut -c 1`
  tar --exclude='opencast/build/opencast-dist-*.tar.*' --exclude='debian' -cvJf opencast-$majorVersion\_$1.orig.tar.xz opencast

  doBuild opencast
  createOutputs $VERSION $1 $3
  mv opencast*.* outputs/$VERSION
}


#Usage: doActiveMQ packageversion branchname friendlyname
#eg: doActiveMQ 5.13.0 r/3.x 3.x
doActiveMQ() {

  git checkout $2

  VERSION=`git rev-parse HEAD`

  tar cvJf activemq-dist_$1.orig.tar.xz activemq
  doBuild activemq
  createOutputs $VERSION $1 $3
  mv activemq*.* outputs/$VERSION
}


#Usage: doFfmpeg packageversion branchname friendlyname
#eg: doFfmpeg 5.13.0 r/3.x 3.x
doFfmpeg() {

  git checkout $2

  VERSION=`git rev-parse HEAD`

  tar cvJf ffmpeg-dist_$1.orig.tar.xz ffmpeg
  doBuild ffmpeg
  createOutputs $VERSION $1 $3
  mv ffmpeg*.* outputs/$VERSION
}

