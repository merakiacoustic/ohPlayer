#!/bin/bash

# Run it in pyenv shell with Python 2

set -e

export PATH=/opt/homebrew/bin:$PATH
export Qt_DIR=~/Qt/6.6.2/macos/
export Qt6_DIR=/opt/homebrew/Cellar/qt/6.6.2_1/lib/cmake/Qt6

#export HWPLATFORM=Mac-x64
if [ "$HWPLATFORM" = "Mac-x64" ]
then
  export CC=clang
  export CXX=clang++
else
  export CC=gcc
  export CXX=g++
fi
export HWPLATFORM=Linux-arm64

#export OHNET_VERSION=1.32.4341
export OHNET_VERSION=ohNet_1.32.4350
#export OHWAFHELPERS_VERSION=0.0.115
#export OHWAFHELPERS_VERSION=0.2.127
export OHWAFHELPERS_VERSION=ohWafHelpers_0.2.127
export LIBRESSL_VERSION=3.8.3
export OHPIPELINE_VERSION=ohMediaPlayer_1.135.984
#export OHNETGENERATED_VERSION=1.1.195
export OHNETGENERATED_VERSION=ohNetGenerated_1.1.143

TOPLEVEL=$PWD

DEPS_DIR=$TOPLEVEL/dependencies/src/$HWPLATFORM

mkdir -p $TOPLEVEL/dependencies/AnyPlatform
mkdir -p $DEPS_DIR

cd $DEPS_DIR || exit
if [ ! -d ohNet ]
then
  git clone https://github.com/openhome/ohNet.git --depth 1 --branch $OHNET_VERSION
fi
cd ohNet || exit
git checkout -- .
patch -p1 < $TOPLEVEL/patches/ohNet.patch
make mac-64=1 release=1 nativeonly=yes uset4=no -j1
cd $TOPLEVEL

cd $DEPS_DIR || exit
if [ ! -d ohNetGenerated ]
then
  git clone https://github.com/openhome/ohNetGenerated.git --depth 1 --branch $OHNETGENERATED_VERSION
fi
cd ohNetGenerated || exit
OHNETGENERATED_DIR=$PWD
git checkout -- .
patch -p1 < $TOPLEVEL/patches/ohNetGenerated.patch
mkdir -p dependencies/$HWPLATFORM
cd $OHNETGENERATED_DIR/dependencies/$HWPLATFORM || exit
tar xf $DEPS_DIR/ohNet/Build/Bundles/ohNet-$HWPLATFORM-Release.tar.gz
cd $OHNETGENERATED_DIR
make mac-64=1 release=1 nativeonly=yes uset4=no -j1
cd $TOPLEVEL

cd $DEPS_DIR || exit
tar xf $TOPLEVEL/thirdparty/libressl-3.8.3.tar.gz
cd libressl-3.8.3 || exit
if [ "$HWPLATFORM" = "Mac-x64" ]
then
  CFLAGS="-arch x86_64"
fi
./configure --prefix=$TOPLEVEL/dependencies/$HWPLATFORM/libressl CC=$CC CXX=$CXX CFLAGS="$CFLAGS"
make
make install
cd $TOPLEVEL

cd $DEPS_DIR || exit
if [ ! -d ohPipeline ]
then
  git clone https://github.com/openhome/ohPipeline.git --depth 1 --branch $OHPIPELINE_VERSION
fi
cd ohPipeline || exit
OHPIPELINE_DIR=$PWD
git checkout -- .
patch -p1 < $TOPLEVEL/patches/ohPipeline.patch
mkdir -p $OHPIPELINE_DIR/dependencies/AnyPlatform
cd $OHPIPELINE_DIR/dependencies/AnyPlatform || exit
if [ ! -d ohWafHelpers ]
then
  git clone https://github.com/openhome/ohWafHelpers.git --depth 1 --branch $OHWAFHELPERS_VERSION
fi
cd ohWafHelpers
git checkout -- .
patch -p1 < $TOPLEVEL/patches/ohWafHelpers.patch
cd $OHPIPELINE_DIR
mkdir -p $OHPIPELINE_DIR/dependencies/$HWPLATFORM
cd $OHPIPELINE_DIR/dependencies/$HWPLATFORM || exit
tar xf $DEPS_DIR/ohNet/Build/Bundles/ohNet-$HWPLATFORM-Release.tar.gz
if [ ! -L $OHPIPELINE_DIR/dependencies/$HWPLATFORM/libressl ]
then
  ln -fs $TOPLEVEL/dependencies/$HWPLATFORM/libressl $OHPIPELINE_DIR/dependencies/$HWPLATFORM/
fi
cd $OHPIPELINE_DIR
python2 waf configure
python2 waf build
python2 waf bundle
cd $TOPLEVEL

mkdir -p $TOPLEVEL/dependencies/$HWPLATFORM
cd $TOPLEVEL/dependencies/$HWPLATFORM || exit
tar xf $DEPS_DIR/ohNet/Build/Bundles/ohNet-$HWPLATFORM-Release.tar.gz
tar xf $DEPS_DIR/ohNetGenerated/Build/Bundles/ohNetGenerated-$HWPLATFORM-Release.tar.gz
tar xf $DEPS_DIR/ohPipeline/build/ohMediaPlayer.tar.gz
cd $TOPLEVEL

#
#conan install . --output-folder=build --build=missing
#cd build
#/opt/homebrew/bin/cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -GNinja
#/opt/homebrew/bin/cmake --build . --verbose
