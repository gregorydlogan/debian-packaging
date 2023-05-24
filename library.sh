#!/bin/bash

#Usage: doBuild directoryname
#eg: doBuild opencast
doBuild() {
  cd $1
  echo "Building $1"
  if [ -z "$SIGNING_KEY" ]; then
    dpkg-buildpackage -k3259FFB3967266533FCD4B249A7EA8E5B3820B26 -tc
  else
    dpkg-buildpackage -k$SIGNING_KEY -tc
  fi
  cd ..
}


#Usage: createOutputs hash branchname friendlyname, falls back to using branch name if friendly is missing
#eg: createOutputs <some git hash> r/3.2 3.2-new
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
    tar -xvf build/$line -C build \
      $archiveName/etc/org.apache.karaf.features.cfg \
      $archiveName/etc/profile.cfg \
      $archiveName/etc/org.opencastproject.serviceregistry.impl.JobDispatcher.cfg
    #Extract the contents of the various tarballs to the common base
    echo "Extracting contents to common base directory"
    tar --strip-components=1 -xf build/$line -C build/opencast-dist-base
    rm -f build/$line
  done
  echo ""
  #Remove the karaf feature configuration file, since that is set with the packages
  rm -f build/opencast-dist-base/etc/org.apache.karaf.features.cfg
  rm -f build/opencast-dist-base/etc/profile.cfg
  rm -f build/opencast-dist-base/etc/org.opencastproject.serviceregistry.impl.JobDispatcher.cfg
  cd ..

  echo "Building source tarball"
  #Exclude the raw tarballs
  majorVersion=`echo $1 | cut -f 1 -d "."`
  tar --exclude='opencast/build/opencast-dist-*.tar.*' --exclude='debian' -cvJf opencast-$majorVersion\_$1.orig.tar.xz opencast

  doBuild opencast
  createOutputs $VERSION $1 $3
  mv opencast*.* outputs/$VERSION
}


#Usage: doFfmpeg packageversion branchname friendlyname buildnumber
#eg: doFfmpeg 20220613051048-N-107098-g4d45f5acbd develop ffmpeg-20220613051048 2
doFfmpeg() {

  git checkout $2

  VERSION=`git rev-parse HEAD`

  cd ffmpeg
  git clean -fdx ./
  tar --strip-components=1 -xvf ../binaries/ffmpeg-*$1*.xz
  version="$1"

  dch --create --package ffmpeg-dist --newversion $1-$4 -D stable -u low "FFmpeg build $4, based on Opencast FFmpeg build $3"
  #Zero out the time
  sed -i 's/..\:..\:../00:00:00/' debian/changelog

  cd ..

  tar cvJf ffmpeg-dist_$version.orig.tar.xz ffmpeg
  doBuild ffmpeg
  createOutputs $VERSION $1 ffmpeg-dist-$version
  mv ffmpeg*.* outputs/$VERSION
}

#Usage: doTobira packageversion branch build
#eg: doTobira 1.3 develop 2
doTobira() {
  git checkout $2
  tobiraVersion=$1
  buildNumber=$3

  friendlyName="tobira-$tobiraVersion-$buildNumber"

  VERSION=`git rev-parse HEAD`

  cd tobira
  git clean -fdx ./
  #This might be the upstream tobira-x86_64-unknown-linux-gnu, or it might be renamed.  Let's wildcard
  ln ../binaries/tobira-$tobiraVersion/tobira* ./tobira
  ln ../binaries/tobira-$tobiraVersion/config.toml ./config.toml

  dch --create --package tobira --newversion $tobiraVersion-$buildNumber -D stable -u low "Tobira version $tobiraVersion, based on Opencast Tobira packaging, build $buildNumber"
  #Zero out the time
  sed -i 's/..\:..\:../00:00:00/' debian/changelog

  cd ..

  tar cvJf tobira_$tobiraVersion.orig.tar.xz tobira
  doBuild tobira
  createOutputs $VERSION $tobiraVersion $friendlyName
  mv tobira*.* outputs/$VERSION
}
