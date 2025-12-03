#!/bin/bash

#Usage: doBuild directoryname [arch] OR [buncha arguments]
#eg: doBuild opencast arm64
#    doBuild whisper -myArg=foo -otherarg=asdf
doBuild() {
  cd $1
  echo "Building $1"
  #Set the arch, if any.  With it unset it defaults to the system arch
  if [ $# -eq 2 ]; then
    params="-a $2"
  else
    params="${@:2}"
  fi

  if [ -z "$SIGNING_KEY" ]; then
    dpkg-buildpackage -k3259FFB3967266533FCD4B249A7EA8E5B3820B26 -tc $params
  else
    dpkg-buildpackage -k$SIGNING_KEY -tc $params
  fi
  success=$?
  cd ..
  if [ 0 -ne $success ]; then
    exit 1
  fi
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


#Usage: doFfmpeg packageversion arch branchname friendlyname buildnumber
#eg: doFfmpeg 20220613051048-N-107098-g4d45f5acbd arm64 develop ffmpeg-20220613051048 2
doFfmpeg() {

  git checkout $3

  VERSION=`git rev-parse HEAD`
  version="$1"
  arch="$2"
  branch="$3"
  outputDir="$4"
  buildNr="$5"

  cd ffmpeg
  git clean -fdx ./
  if [ "$arch" == "amd64" ]; then
    subarch="64"
  elif [ "$arch" == "arm64" ]; then
    subarch="arm64"
  fi
  tar --strip-components=1 -xvf ../binaries/ffmpeg-$version-linux$subarch-gpl-${version:1:3}.tar.xz

  dch --create --package ffmpeg-dist --newversion ${version:1}-$buildNr -D stable -u low "FFmpeg build $buildNr for $arch, based on Opencast FFmpeg build $version-linux$subarch-gpl-${version:1:3}.tar.xz.  Original build sourced from https://github.com/BtbN/FFmpeg-Builds/releases"
  #Zero out the time
  sed -i 's/..\:..\:../00:00:00/' debian/changelog
  #Set the target arch
  sed -i "s/TARGET_ARCH/$arch/" debian/control

  cd ..

  #Turning the source tar off since we don't need it now
  #tar cvJf ffmpeg-dist_${version:1}.orig.tar.xz ffmpeg
  #Do the build, setting the arch and specifying a binary only build
  # We're building binary only here because otherwise the *sources* for amd64 and arm64 conflict
  # Debian assumes that we've got source, and then build exactly the same source in multiple arch
  # That's not what we're doing here, so of course the sources differ but have the same package name
  # This could also be fixed by renaming the package cf ffmpeg-dist-$arch
  doBuild ffmpeg -a $arch -b
  createOutputs $VERSION $version ffmpeg-dist-$version-$buildNr
  mv ffmpeg*.* outputs/$VERSION
  #Cleanup for the next build
  git checkout -- ffmpeg/debian/control
  rm -f debian/changelog
}

#Usage: doAnalysis packageversion branchname friendlyname buildnumber
#eg: doAnalysis 1.3.16 develop 2
doAnalysis() {

  VERSION=`git rev-parse HEAD`
  version="$1"
  branch="$2"
  buildNr="$3"

  cd binaries
  ./analysis-icu-fetch.sh $version
  cd ..

  cd analysis-icu
  git clean -fdx ./
  unzip ../binaries/analysis-icu-$version.zip

  dch --create --package opensearch-analysis-icu --newversion $version-$buildNr -D stable -u low "Packaged analysis-icu plugin version $version, build $buildNr using Opencast Debian packaging scripts version $VERSION.  Original build sourced from Opensearch artifacts repository."
  #Zero out the time
  sed -i 's/..\:..\:../00:00:00/' debian/changelog
  #Set the depends version
  sed -i "s/opensearch (= x)/opensearch (= $version)/" debian/control

  cd ..

  tar cvJf opensearch-analysis-icu_$version.orig.tar.xz analysis-icu
  doBuild analysis-icu
  createOutputs $VERSION $version opensearch-analysis-icu-$version-$buildNr
  mv opensearch-analysis-icu*.* outputs/$VERSION
  #Cleanup for the next build
  git checkout -- analysis-icu/debian/control
  rm -f debian/changelog
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

#Usage: doOctoka packageversion branch build
#eg: doOctoka 1.3 develop 2
doOctoka() {
  git checkout $2
  octokaVersion=$1
  buildNumber=$3

  friendlyName="octoka-$octokaVersion-$buildNumber"

  VERSION=`git rev-parse HEAD`

  cd octoka
  git clean -fdx ./
  ln ../binaries/octoka-$octokaVersion/octoka ./octoka
  ln ../binaries/octoka-$octokaVersion/config.toml ./config.toml

  dch --create --package octoka --newversion $octokaVersion-$buildNumber -D stable -u low "Octoka version $octokaVersion, based on Opencast Tobira packaging, build $buildNumber"
  #Zero out the time
  sed -i 's/..\:..\:../00:00:00/' debian/changelog

  cd ..

  tar cvJf octoka_$octokaVersion.orig.tar.xz octoka
  doBuild octoka
  createOutputs $VERSION $octokaVersion $friendlyName
  mv octoka*.* outputs/$VERSION
}

doWhisper() {
  git checkout $2
  whisperVersion=$1
  buildNumber=$3

  friendlyName="whisper-$whisperVersion-$buildNumber"
  VERSION=`git rev-parse HEAD`

  cd whisper.cpp
  git clean -fdx ./
  sed -i "s/WHISPER_VERSION/$whisperVersion/g" debian/whisper.cpp.install
  tar --strip-components=1 -xvf ../binaries/whisper.cpp-$whisperVersion/whisper.cpp-$whisperVersion.tar.gz
  cd ..
  #NB: Creating the source tarball here so that we don't include the models!
  tar -cvJf whisper.cpp_$whisperVersion.orig.tar.xz whisper.cpp
  cd whisper.cpp
  #This fetches the models, and takes (currently) 9.4GB
  if [ -d ../binaries/models/$whisperVersion ]; then
    ls ../binaries/models/$whisperVersion | while read line; do
      ln ../binaries/models/$whisperVersion/$line models
    done
  else
    mkdir -p ../binaries/models/$whisperVersion
    #Fetch the models
    for modelsize in tiny base small medium large-v1 large-v2 large-v3
    do
      if [ ! -f ./models/ggml-$modelsize.bin ]; then
        ./models/download-ggml-model.sh $modelsize
        ln models/ggml-$modelsize.bin ../binaries/models/$whisperVersion
      fi
    done
    for vadmodel in silero-v5.1.2
    do
      if [ ! -f ./models/$vadmodel.bin ]; then
        ./models/download-vad-model.sh $vadmodel
        ln models/ggml-$vadmodel.bin ../binaries/models/$whisperVersion
      fi
    done
  fi

  dch --create --package whisper.cpp --newversion $whisperVersion-$buildNumber -D stable -u low "Whisper.cpp version $whisperVersion, based on Opencast Whisper.cpp packaging, build $buildNumber"
  #Zero out the time
  sed -i 's/..\:..\:../00:00:00/' debian/changelog
  cd ..

  #We need to pass the extra flags, so we don't use doBuild here
  doBuild whisper.cpp --diff-ignore=models/ggml.*.bin --tar-ignore=models/ggml.*.bin
  createOutputs $VERSION $whisperVersion $friendlyName
  mv whisper.cpp*.* outputs/$VERSION
}
