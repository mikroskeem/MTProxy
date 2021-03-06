#!/bin/bash

LIBRESSL_URL="https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.8.2.tar.gz"
LIBZ_URL="https://sortix.org/libz/release/libz-1.2.8.2015.12.26.tar.gz"
LIBEXECINFO_URL="https://github.com/mikroskeem/libexecinfo/archive/1.1-2.tar.gz"

BUILDROOT="$(pwd)/musl_buildroot"
LIBRESSL_SRC="${BUILDROOT}/libressl-src.tar.gz"
LIBZ_SRC="${BUILDROOT}/libz-src.tar.gz"
LIBEXECINFO_SRC="${BUILDROOT}/libexecinfo-src.tar.gz"

export CC="musl-gcc"

# Set up libraries for musl libc
if [ ! -d "${BUILDROOT}" ] || [ "${1}" = "buildroot" ]; then
    mkdir -p "${BUILDROOT}"
    rm -rf "${BUILDROOT}"/*/

    # Download
    [ -f "${LIBRESSL_SRC}" ] || curl -o "${LIBRESSL_SRC}" "${LIBRESSL_URL}"
    [ -f "${LIBZ_SRC}" ] || curl -o "${LIBZ_SRC}" "${LIBZ_URL}"
    [ -f "${LIBEXECINFO_SRC}" ] || curl -L -o "${LIBEXECINFO_SRC}" "${LIBEXECINFO_URL}"

    # Build LibreSSL
    cd "${BUILDROOT}" || exit 1
    tar xvf "${LIBRESSL_SRC}"
    cd libressl-*/ || exit 1

    mkdir build && cd build || exit 1;
    ../configure --prefix="${BUILDROOT}" \
        --with-openssldir=/etc/ssl
    make -j"$(grep -c ^processor /proc/cpuinfo)"
    make install

    # Build libz
    cd "${BUILDROOT}" || exit 1
    tar xvf "${LIBZ_SRC}"
    cd libz-*/ || exit 1

    mkdir build && cd build || exit 1;
    ../configure --prefix="${BUILDROOT}"
    make -j"$(grep -c ^processor /proc/cpuinfo)"
    make install

    # Build libexecinfo
    cd "${BUILDROOT}" || exit 1
    tar xvf "${LIBEXECINFO_SRC}"
    cd libexecinfo-*/ || exit 1

    CFLAGS="-fno-omit-frame-pointer" make -j"$(grep -c ^processor /proc/cpuinfo)" all
    make DESTDIR="${BUILDROOT}" install

    # Cleanup
    cd "${BUILDROOT}" || exit 1
    rm -rf libressl-*/
    rm -rf libz-*/
    rm -rf libexecinfo-*/

    cd "${BUILDROOT}/.." || exit 1
fi

[ "${1}" = "buildroot" ] && exit 0

export CC="musl-gcc -static -L\"${BUILDROOT}/lib\" -I\"${BUILDROOT}/include\" -DMPQ_USE_POSIX_SEMAPHORES=1"
make EXTRA_LDFLAGS="-lexecinfo" \
    -j"$(grep -c ^processor /proc/cpuinfo)"
