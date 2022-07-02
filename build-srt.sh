#!/bin/sh

set -e
set -x

dir="$(cd $(dirname $0) && pwd)"

VERSION="${VERSION:=1.5.0}"
test -f srt-${VERSION}.zip || \
    curl -L -o srt-${VERSION}.zip https://github.com/Haivision/srt/archive/refs/tags/v${VERSION}.zip
test -d srt-${VERSION} || \
    unzip srt-${VERSION}.zip
(
    patch -f -p0 < ${dir}/patches/patch-srt-${VERSION}.txt
) || true

AR="${AR:=ar}"
CC="${CC:=clang}"
CXX="${CXX:=clang++}"
LD="${LD:=${CXX}}"
MAKE="${MAKE:=make}"

TARGET="${TARGET:=$(${CC} ${CFLAGS} -dumpmachine | sed -e 's/[0-9.]*$//')}"

test -f "build/${TARGET}/lib/libsrt.dylib" && exit 0
test -f "build/${TARGET}/lib/libsrt.so" && exit 0

DESTDIR="${DESTDIR:=${dir}/build/${TARGET}}"
PREFIX="${PREFIX:=/.}"

if test "${DEBUG}" = "0"; then
    CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release ${CMAKE_ARGS}"
else
    CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Debug ${CMAKE_ARGS}"
    CMAKE_ARGS="-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON ${CMAKE_ARGS}"
fi

case "${CC}" in
    *clang)
        CFLAGS="--target=${TARGET} ${CFLAGS}"
        CXXFLAGS="--target=${TARGET} ${CXXFLAGS}"
        ;;
    *)
        ;;
esac
case "${TARGET}" in
    arm64-*-*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_PROCESSOR=arm64 ${CMAKE_ARGS}"
        ;;
    x86_64-*-*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_PROCESSOR=x86_64 ${CMAKE_ARGS}"
        ;;
    *)
        ;;
esac
case "${TARGET}" in
    *-*-darwin*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_NAME=Darwin ${CMAKE_ARGS}"
        SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
        CMAKE_ARGS="-DCMAKE_SYSROOT=${SDKROOT} ${CMAKE_ARGS}"
        ;;
    *-*-ios*)
        CMAKE_ARGS="-DCMAKE_SYSTEM_NAME=iOS ${CMAKE_ARGS}"
        SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
        CMAKE_ARGS="-DCMAKE_SYSROOT=${SDKROOT} ${CMAKE_ARGS}"
        ;;
    *-*-android*)
        CMAKE_ARGS="-DANDROID=1 ${CMAKE_ARGS}"
        CMAKE_ARGS="-DCMAKE_SYSTEM_NAME=Linux ${CMAKE_ARGS}"
        ;;
    *)
        ;;
esac
case "${TARGET}" in
    *-*-android*)
        AR="$(which ${AR})"
        CC="$(which ${CC})"
        CXX="$(which ${CXX})"
        LD="$(which ${LD})"
        ;;
    *-*-darwin*)
        AR="$(xcrun --sdk macosx --find ${AR})"
        CC="$(xcrun --sdk macosx --find ${CC})"
        CXX="$(xcrun --sdk macosx --find ${CXX})"
        LD="$(xcrun --sdk macosx --find ${LD})"
        ;;
    *-*-ios*)
        AR="$(xcrun --sdk iphoneos --find ${AR})"
        CC="$(xcrun --sdk iphoneos --find ${CC})"
        CXX="$(xcrun --sdk iphoneos --find ${CXX})"
        LD="$(xcrun --sdk iphoneos --find ${LD})"
        ;;
    *)
        ;;
esac

CMAKE_ARGS="-DCMAKE_C_COMPILER=${CC} ${CMAKE_ARGS}"
CMAKE_ARGS="-DCMAKE_CXX_COMPILER=${CXX} ${CMAKE_ARGS}"
CMAKE_ARGS="-DCMAKE_C_COMPILER_TARGET=${TARGET} ${CMAKE_ARGS}"
CMAKE_ARGS="-DCMAKE_CXX_COMPILER_TARGET=${TARGET} ${CMAKE_ARGS}"
CMAKE_ARGS="-DCMAKE_AR=${AR} ${CMAKE_ARGS}"
CMAKE_ARGS="-DCMAKE_MAKE_PROGRAM=${MAKE} ${CMAKE_ARGS}"

CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${PREFIX}"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_BINDIR=${PREFIX}/bin"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_INCLUDEDIR=${PREFIX}/include"

CMAKE_ARGS="${CMAKE_ARGS} -DUSE_ENCLIB=mbedtls"
CMAKE_ARGS="${CMAKE_ARGS} -DSTATIC_MBEDTLS=FALSE"
CMAKE_ARGS="${CMAKE_ARGS} -DMBEDTLS_INCLUDE_DIR=${DESTDIR}/include"
CMAKE_ARGS="${CMAKE_ARGS} -DMBEDTLS_INCLUDE_DIRS=${DESTDIR}/include"
CMAKE_ARGS="${CMAKE_ARGS} -DMBEDTLS_LIBRARIES=${DESTDIR}/lib/libmbedtls.so"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_CXX11=ON"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_STDCXX_SYNC=ON"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_DEBUG=2"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_LOGGING=0"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_HEAVY_LOGGING=0"
CMAKE_ARGS="${CMAKE_ARGS} -DENABLE_APPS=0"

export AR
export CC
export CXX
export LD
export CFLAGS="${CPPFLAGS} ${CFLAGS}"
export CXXFLAGS="${CPPFLAGS} ${CXXFLAGS}"
export LDFLAGS

cd srt-${VERSION}
rm -rf build
mkdir -p build
cd build
cmake ${CMAKE_ARGS} ..
make
make install DESTDIR="${DESTDIR}" PREFIX="${PREFIX}"
