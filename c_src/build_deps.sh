#!/bin/sh

export PATH=/root/x-tools/arm-plum-linux-gnueabi/bin:$PATH

# /bin/sh on Solaris is not a POSIX compatible shell, but /usr/bin/ksh is.
if [ `uname -s` = 'SunOS' -a "${POSIX_SHELL}" != "true" ]; then
    POSIX_SHELL="true"
    export POSIX_SHELL
    exec /usr/bin/ksh $0 $@
fi
unset POSIX_SHELL # clear it so if we invoke other scripts, they run as ksh as well

LEVELDB_VSN="v1.18"

SNAPPY_VSN="1.0.4"

set -e

if [ `basename $PWD` != "c_src" ]; then
    # originally "pushd c_src" of bash
    # but no need to use directory stack push here
    cd c_src
fi

BASEDIR="$PWD"

# detecting gmake and if exists use it
# if not use make
# (code from github.com/tuncer/re2/c_src/build_deps.sh
which gmake 1>/dev/null 2>/dev/null && MAKE=gmake
MAKE=${MAKE:-make}

# Changed "make" to $MAKE

case "$1" in
    rm-deps)
        rm -rf leveldb system snappy-$SNAPPY_VSN
        ;;

    clean)
        rm -rf system snappy-$SNAPPY_VSN
        if [ -d leveldb ]; then
            (cd leveldb && $MAKE clean)
        fi
        ;;

    test)
        export CFLAGS="$CFLAGS -I $BASEDIR/system/include"
        export CXXFLAGS="$CXXFLAGS -I $BASEDIR/system/include"
        export LDFLAGS="$LDFLAGS -L$BASEDIR/system/lib"
        export LD_LIBRARY_PATH="$BASEDIR/system/lib:$LD_LIBRARY_PATH"

        (cd leveldb && $MAKE check)

        ;;

    get-deps)
        if [ ! -d leveldb ]; then
            git clone git://github.com/plumlife/leveldb
            (cd leveldb && git checkout ARM32)
        fi
        ;;

    *)
        if [ ! -d snappy-$SNAPPY_VSN ]; then
            tar -xzf snappy-$SNAPPY_VSN.tar.gz
            (cd snappy-$SNAPPY_VSN && ./configure --host=arm-linux-gnueabi --prefix=$BASEDIR/system --libdir=$BASEDIR/system/lib --with-pic)
        fi
        
        export CC="arm-plum-linux-gnueabi-gcc"
        export CXX="arm-plum-linux-gnueabi-g++"
        export AR="arm-plum-linux-gnueabi-ar"
        export RANLIB="arm-plum-linux-gnueabi-ranlib"

        (cd snappy-$SNAPPY_VSN && $MAKE && $MAKE install)

        export CFLAGS="$CFLAGS -I $BASEDIR/system/include"
        export CXXFLAGS="$CXXFLAGS -I $BASEDIR/system/include"
        export LDFLAGS="$LDFLAGS -L$BASEDIR/system/lib"
        export LD_LIBRARY_PATH="$BASEDIR/system/lib:$LD_LIBRARY_PATH"
        export TARGET_OS="OS_LINUX_ARM_CROSSCOMPILE"

        if [ ! -d leveldb ]; then
            git clone git://github.com/google/leveldb
            (cd leveldb && git checkout $LEVELDB_VSN)
        fi

        (cd leveldb && $MAKE all)

        ;;
esac
