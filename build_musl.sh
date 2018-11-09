#!/bin/bash

LIBRESSL_URL="https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.8.2.tar.gz"
ZLIB_URL="https://zlib.net/zlib-1.2.11.tar.gz"
LIBEXECINFO_URL="https://github.com/mikroskeem/libexecinfo/archive/1.1-2.tar.gz"

BUILDROOT="$(pwd)/musl_buildroot"
LIBRESSL_SRC="${BUILDROOT}/libressl-src.tar.gz"
ZLIB_SRC="${BUILDROOT}/zlib-src.tar.gz"
LIBEXECINFO_SRC="${BUILDROOT}/libexecinfo-src.tar.gz"

export CC="musl-gcc"

# Set up libraries for musl libc
if [ ! -d "${BUILDROOT}" ]; then
    mkdir -p "${BUILDROOT}"

    # Download
    curl -o "${LIBRESSL_SRC}" "${LIBRESSL_URL}"
    curl -o "${ZLIB_SRC}" "${ZLIB_URL}"
    curl -L -o "${LIBEXECINFO_SRC}" "${LIBEXECINFO_URL}"

    # Build LibreSSL
    cd "${BUILDROOT}" || exit 1
    tar xvf "${LIBRESSL_SRC}"
    cd libressl-*/ || exit 1

    (mkdir build && cd build) || exit 1;
    ./configure --prefix="${BUILDROOT}"
    make -j"$(grep -c ^processor /proc/cpuinfo)"
    make install

    # Build zlib
    cd "${BUILDROOT}" || exit 1
    tar xvf "${ZLIB_SRC}"
    cd zlib-*/ || exit 1

    (mkdir build && cd build) || exit 1;
    ./configure --prefix="${BUILDROOT}"
    make -j"$(grep -c ^processor /proc/cpuinfo)"
    make install

    # Build libexecinfo
    cd "${BUILDROOT}" || exit 1
    tar xvf "${LIBEXECINFO_SRC}"
    cd libexecinfo-*/ || exit 1

    (mkdir build && cd build) || exit 1;
    CFLAGS="-fno-omit-frame-pointer" make -j"$(grep -c ^processor /proc/cpuinfo)" all
    make DESTDIR="${BUILDROOT}" install

    # Cleanup
    cd "${BUILDROOT}" || exit 1
    rm -rf libressl-*/
    rm -rf zlib-*/
    rm -rf libexecinfo-*/

    cd "${BUILDROOT}/.." || exit 1
fi

export CC="musl-gcc -lexecinfo -static -L\"${BUILDROOT}/lib\" -I\"${BUILDROOT}/include\" -DMPQ_USE_POSIX_SEMAPHORES=1"
make EXTRA_LDFLAGS="-lexecinfo" \
    -j"$(grep -c ^processor /proc/cpuinfo)"
