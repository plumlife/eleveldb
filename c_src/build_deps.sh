#!/bin/bash

export PATH="/root/x-tools/arm-plum-linux-gnueabi/bin:${PATH}"

CROSS="arm-plum-linux-gnueabi"

LEVELDB_VSN="1.18"
SNAPPY_VSN="1.0.4"
MAKE=make

set -e

if [ `basename $PWD` != "c_src" ]; then
    pushd c_src
fi

BASEDIR="${PWD}"

case "$1" in
    clean)
        rm -rf leveldb system snappy-$SNAPPY_VSN
        ;;

    test)
        export CFLAGS="${CFLAGS} -I ${BASEDIR}/system/include"
        export LDFLAGS="${LDFLAGS} -L ${BASEDIR}/system/lib"
        export LD_LIBRARY_PATH="${BASEDIR}/system/lib:${LD_LIBRARY_PATH}"

        (cd leveldb && make check)

        ;;
    *)
        if [ ! -d "snappy-${SNAPPY_VSN}" ]; then
            tar -xzf "snappy-${SNAPPY_VSN}.tar.gz"
            (cd "snappy-${SNAPPY_VSN}" && ./configure --host="${CROSS}" --prefix="${BASEDIR}/system" --libdir="${BASEDIR}/system/lib" --with-pic)
        fi
        
        export CC="${CROSS}-gcc"
        export CXX="${CROSS}-g++"
        export AR="${CROSS}-ar"
        export RANLIB="${CROSS}-ranlib"
        export LD="${CROSS}-ld"
        export LDD="${CROSS}-ldd"
        export ELFEDIT="${CROSS}-elfedit"
        export STRIP="${CROSS}-strip"

        (cd "snappy-${SNAPPY_VSN}" && $MAKE && $MAKE install)

        export CFLAGS="${CFLAGS} -I ${BASEDIR}/system/include"
        export CXXFLAGS="${CXXFLAGS} -I ${BASEDIR}/system/include"
        export LDFLAGS="${LDFLAGS} -L${BASEDIR}/system/lib"
        export LD_LIBRARY_PATH="${BASEDIR}/system/lib:${LD_LIBRARY_PATH}"
        export TARGET_OS="OS_LINUX_ARM_CROSSCOMPILE"

        if [ ! -d leveldb ]; then
            git clone git://github.com/plumlife/leveldb
            (cd leveldb && git checkout "ARM32-${LEVELDB_VSN}")
        fi

        (cd leveldb && $MAKE all)

        ;;
esac
