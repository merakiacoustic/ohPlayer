#!/bin/bash

# Run it in pyenv shell with Python 2

set -e

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	case $(uname -m) in
	x86_64) export HWPLATFORM=Linux-x64 ;;
	arm) dpkg --print-architecture | grep -q "arm64" && export HWPLATFORM=Linux-arm64 || export HWPLATFORM=Linux-armhf ;;
	esac
elif [[ "$OSTYPE" == "darwin"* ]]; then
	export HWPLATFORM=Mac-x64
elif [[ "$OSTYPE" == "cygwin" ]]; then
	echo FIXME - No Windows support yet
	exit 1
elif [[ "$OSTYPE" == "msys" ]]; then
	echo FIXME - No Windows support yet
	exit 1
elif [[ "$OSTYPE" == "win32" ]]; then
	echo FIXME - No Windows support yet
	exit 1
else
	echo "Cannot detect platform. Exiting."
	exit 1
fi

if [ "$HWPLATFORM" = "Mac-x64" ]; then
	export CC=clang
	export CXX=clang++
	export EXTRA_MAKE_FLAGS=mac-64=1
else
	export CC=gcc
	export CXX=g++
fi

if [ "$1" = "--debug" ]; then
	BUILD_TYPE=Debug
	OHNET_EXTRA_ARGS="debug=1"
	OHNETGENERATED_EXTRA_ARGS="debug=1"
	OHPIPELINE_CONFIGURE_EXTRA_ARGS="--debug"
	OHPLAYER_EXTRA_ARGS="DEBUG=1"
fi

#export OHNET_VERSION=1.32.4341 # Original
#export OHNET_VERSION=ohNet_1.32.4350 # Closest compatible
#export OHNET_VERSION=ohNet_1.36.5182 # Conan version
export OHNET_VERSION=ohNet_1.36.5344 # Latest
#export OHWAFHELPERS_VERSION=0.0.115
#export OHWAFHELPERS_VERSION=0.2.127
export OHWAFHELPERS_VERSION=ohWafHelpers_0.2.127
export LIBRESSL_VERSION=3.8.3
#export OHPIPELINE_VERSION=ohMediaPlayer_1.135.984 # Original
#export OHPIPELINE_VERSION=ohMediaPlayer_1.139.1000 # Conan version
#export OHPIPELINE_VERSION=ohMediaPlayer_1.146.1067 # VERSION in thirdparty fixed
#export OHPIPELINE_VERSION=ohMediaPlayer_1.149.1084 # limits in ProtocolHls fixed
#export OHPIPELINE_VERSION=ohMediaPlayer_1.151.1100 # fpm fixed
export OHPIPELINE_VERSION=ohMediaPlayer_1.155.1133 # Latest
#export OHNETGENERATED_VERSION=1.1.195 # Original
export OHNETGENERATED_VERSION=ohNetGenerated_1.1.143 # Closest compatible and latest

TOPLEVEL=$PWD

DEPS_DIR=$TOPLEVEL/dependencies/src/$HWPLATFORM

mkdir -p $TOPLEVEL/dependencies/AnyPlatform
mkdir -p $DEPS_DIR

cd $DEPS_DIR || exit
if [ ! -d ohNet ]; then
	git clone https://github.com/openhome/ohNet.git --depth 1 --branch $OHNET_VERSION
fi
cd ohNet || exit
git checkout -- .
if [ -f $TOPLEVEL/patches/$OHNET_VERSION/ohNet.patch ]; then
	patch -p1 <$TOPLEVEL/patches/$OHNET_VERSION/ohNet.patch
fi
make ohNetDll TestsNative proxies devices bundle $EXTRA_MAKE_FLAGS release=1 uset4=no $OHNET_EXTRA_ARGS -j1
cd $TOPLEVEL

cd $DEPS_DIR || exit
if [ ! -d ohNetGenerated ]; then
	git clone https://github.com/openhome/ohNetGenerated.git --depth 1 --branch $OHNETGENERATED_VERSION
fi
cd ohNetGenerated || exit
OHNETGENERATED_DIR=$PWD
git checkout -- .
patch -p1 <$TOPLEVEL/patches/ohNetGenerated.patch
mkdir -p dependencies/$HWPLATFORM
cd $OHNETGENERATED_DIR/dependencies/$HWPLATFORM || exit
tar xf $DEPS_DIR/ohNet/Build/Bundles/ohNet-$HWPLATFORM-Release.tar.gz
cd $OHNETGENERATED_DIR
make make_obj_dir copy_build_includes proxies devices bundle $EXTRA_MAKE_FLAGS release=1 uset4=no $OHNETGENERATED_EXTRA_ARGS -j1
cd $TOPLEVEL

cd $DEPS_DIR || exit
tar xf $TOPLEVEL/thirdparty/libressl-3.8.3.tar.gz
cd libressl-3.8.3 || exit
if [ "$HWPLATFORM" = "Mac-x64" ]; then
	CFLAGS="-arch x86_64"
fi
./configure --prefix=$TOPLEVEL/dependencies/$HWPLATFORM/libressl CC=$CC CXX=$CXX CFLAGS="$CFLAGS"
make
make install
cd $TOPLEVEL

cd $DEPS_DIR || exit
if [ ! -d ohPipeline ]; then
	git clone https://github.com/openhome/ohPipeline.git --depth 1 --branch $OHPIPELINE_VERSION
fi
cd ohPipeline || exit
OHPIPELINE_DIR=$PWD
git checkout -- .
if [ -f thirdparty/libmad-0.15.1b/VERSION.txt ]; then
	rm thirdparty/libmad-0.15.1b/VERSION.txt
fi
if [ -f $TOPLEVEL/patches/$OHPIPELINE_VERSION/ohPipeline.patch ]; then
	patch -p1 <$TOPLEVEL/patches/$OHPIPELINE_VERSION/ohPipeline.patch
fi
mkdir -p $OHPIPELINE_DIR/dependencies/AnyPlatform
cd $OHPIPELINE_DIR/dependencies/AnyPlatform || exit
if [ ! -d ohWafHelpers ]; then
	git clone https://github.com/openhome/ohWafHelpers.git --depth 1 --branch $OHWAFHELPERS_VERSION
fi
cd ohWafHelpers
git checkout -- .
patch -p1 <$TOPLEVEL/patches/ohWafHelpers.patch
cd $OHPIPELINE_DIR
mkdir -p $OHPIPELINE_DIR/dependencies/$HWPLATFORM
cd $OHPIPELINE_DIR/dependencies/$HWPLATFORM || exit
tar xf $DEPS_DIR/ohNet/Build/Bundles/ohNet-$HWPLATFORM-Release.tar.gz
if [ ! -L $OHPIPELINE_DIR/dependencies/$HWPLATFORM/libressl ]; then
	ln -fs $TOPLEVEL/dependencies/$HWPLATFORM/libressl $OHPIPELINE_DIR/dependencies/$HWPLATFORM/
fi
cd $OHPIPELINE_DIR
python2 waf configure "$OHPIPELINE_CONFIGURE_EXTRA_ARGS"
python2 waf build
python2 waf bundle
cd $TOPLEVEL

mkdir -p $TOPLEVEL/dependencies/$HWPLATFORM
cd $TOPLEVEL/dependencies/$HWPLATFORM || exit
tar xf $DEPS_DIR/ohNet/Build/Bundles/ohNet-$HWPLATFORM-Release.tar.gz
tar xf $DEPS_DIR/ohNetGenerated/Build/Bundles/ohNetGenerated-$HWPLATFORM-Release.tar.gz
tar xf $DEPS_DIR/ohPipeline/build/ohMediaPlayer.tar.gz
cd $TOPLEVEL

cd linux
make -f Makefile.ubuntu DISABLE_GTK=1 PLATFORM="$HWPLATFORM" "$OHPLAYER_EXTRA_ARGS"
cd $TOPLEVEL

#conan install . --output-folder=build/$HWPLATFORM/ --build=missing
#cd build/$HWPLATFORM
#/opt/homebrew/bin/cmake $TOPDIR -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -GNinja
#/opt/homebrew/bin/cmake --build . --verbose
