#!/bin/sh

ROOT=$(pwd)
DEPENDDIR=$ROOT/tools/darwin/depends
DEPEND_HASH=$(git rev-list -1 HEAD -- $DEPENDDIR | cut -c1-8)
FFMPEG_HASH=$(git rev-list -1 HEAD -- $ROOT/lib/ffmpeg | cut -c1-8)

target_os=$1

if [ -z $target_os ]; then
  target_os="osx"
fi

if [ $target_os = "ios" ]; then
  darwin="ios"
  arch="armv7"
elif [ $target_os = "osx" ]; then
  darwin="osx"
  arch="i386"
elif [ $target_os = "osx64" ]; then
  darwin="osx"
  arch="x86_64"
fi

echo "-- Getting depends for $darwin-$arch (xbmc-$DEPEND_HASH ffmpeg-$FFMPEG_HASH)"

xcodepath=$(xcode-select -print-path)
xcodebuild=$xcodepath/usr/bin/xcodebuild
if [ $darwin = "osx" ]; then
  sdkversion=$($xcodebuild -showsdks | grep macosx | sort |  tail -n 1 | grep -oE 'macosx[0-9.0-9]+' | cut -c 7-$NF)
else
  sdkversion=$($xcodebuild -showsdks | grep iphoneos | sort | tail -n 1 | awk '{ print $2}')
fi

if [ $darwin = "osx" ]; then
  outputdir=macosx${sdkversion}_$arch
else
  outputdir=iphoneos${sdkversion}_$arch
fi
outputpath=$ROOT/plex/Dependencies/xbmc-depends/$outputdir

function fail
{
  echo "Failed to find dependencies for $1 ($2) - it might not have been built yet."
  exit 1
}

if [ ! -d plex/Dependencies/$outputdir-xbmc-$DEPEND_HASH -o ! -d plex/Dependencies/$outputdir-ffmpeg-$FFMPEG_HASH ]; then
  curl --head --fail -s http://nightlies.plexapp.com/plex-dependencies/pht-depends/$outputdir-xbmc-$DEPEND_HASH.tar.xz > /dev/null || fail xbmc $DEPEND_HASH
  curl --head --fail -s http://nightlies.plexapp.com/plex-dependencies/pht-depends/$outputdir-ffmpeg-$FFMPEG_HASH.tar.xz > /dev/null || fail ffmpeg $FFMPEG_HASH
  
  echo "-- Fetching http://nightlies.plexapp.com/plex-dependencies/pht-depends/$outputdir-xbmc-$DEPEND_HASH.tar.xz"
  curl -s --fail http://nightlies.plexapp.com/plex-dependencies/pht-depends/$outputdir-xbmc-$DEPEND_HASH.tar.xz -o /tmp/$outputdir-xbmc-$DEPEND_HASH.tar.xz || fail xbmc $DEPEND_HASH  
  echo "-- Fetching http://nightlies.plexapp.com/plex-dependencies/pht-depends/$outputdir-ffmpeg-$FFMPEG_HASH.tar.xz"
  curl -s --fail http://nightlies.plexapp.com/plex-dependencies/pht-depends/$outputdir-ffmpeg-$FFMPEG_HASH.tar.xz -o /tmp/$outputdir-ffmpeg-$FFMPEG_HASH.tar.xz || fail ffmpeg $FFMPEG_HASH
  
  echo "-- Unpacking $outputdir-xbmc-$DEPEND_HASH.tar.xz"
  gtar -xaf /tmp/$outputdir-xbmc-$DEPEND_HASH.tar.xz -C plex/Dependencies
  mv plex/Dependencies/$outputdir plex/Dependencies/$outputdir-xbmc-$DEPEND_HASH
  plex/scripts/fix_install_names.py $ROOT/plex/Dependencies/$outputdir-xbmc-$DEPEND_HASH
  
  echo "-- Unpacking $outputdir-ffmpeg-$FFMPEG_HASH.tar.xz"
  gtar -xaf /tmp/$outputdir-ffmpeg-$FFMPEG_HASH.tar.xz -C plex/Dependencies
  mv plex/Dependencies/ffmpeg-$outputdir plex/Dependencies/$outputdir-ffmpeg-$FFMPEG_HASH
  plex/scripts/fix_install_names.py $ROOT/plex/Dependencies/$outputdir-ffmpeg-$FFMPEG_HASH
fi

if [ -e plex/Dependencies/laika-depends ]; then
  rm plex/Dependencies/laika-depends
fi

if [ -e plex/Dependencies/ffmpeg-depends ]; then
  rm plex/Dependencies/ffmpeg-depends
fi


ln -s $outputdir-xbmc-$DEPEND_HASH plex/Dependencies/laika-depends
ln -s $outputdir-ffmpeg-$FFMPEG_HASH plex/Dependencies/ffmpeg-depends
