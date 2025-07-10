#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export OUTDIR="${PWD}/cross"
export SRCDIR="${PWD}/src"
export WORKDIR="${PWD}/build"
export PATH="${OUTDIR}/bin:$PATH"

export MAKE_VERSION="make-4.4.1"
export BINUTILS_VERSION="binutils-2.42"
export GCC_VERSION="gcc-14.1.0"
export GDB_VERSION="gdb-15.1"
export GMP_VERSION="gmp-6.2.1"
export MPFR_VERSION="mpfr-4.1.0"

export MAKE_URL="https://ftp.gnu.org/gnu/make/${MAKE_VERSION}.tar.gz"
export BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/${BINUTILS_VERSION}.tar.xz"
export GCC_URL="https://ftp.gnu.org/gnu/gcc/${GCC_VERSION}/${GCC_VERSION}.tar.xz"
export GDB_URL="https://ftp.gnu.org/gnu/gdb/${GDB_VERSION}.tar.xz"
export GMP_URL="https://ftp.gnu.org/gnu/gmp/${GMP_VERSION}.tar.xz"
export MPFR_URL="https://ftp.gnu.org/gnu/mpfr/${MPFR_VERSION}.tar.xz"

export REDZONE_PATCH="${PWD}/redzone.patch"

setup_dirs() {
    mkdir -p "${SRCDIR}"
    mkdir -p "${WORKDIR}"
    mkdir -p "${OUTDIR}"
}

# get_project
# Downloads a project from a project URL to the sourcedir
# Argument 1: the project version (ex: "binutils-2.42")
# Argument 2: the project URL (ex: "https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz")
get_project() {
    local PROJECT_VERSION PROJECT_URL PROJECT_ZIPNAME

    PROJECT_VERSION="${1}"
    PROJECT_URL="${2}"
    PROJECT_ZIPNAME="$(basename "${PROJECT_URL}")"

    if [[ -d "${SRCDIR}/${PROJECT_VERSION}" ]]; then
        return
    fi

    cd "${SRCDIR}" || exit
    wget "${PROJECT_URL}"
    tar -xf "${SRCDIR}/${PROJECT_ZIPNAME}"
    rm "${SRCDIR}/${PROJECT_ZIPNAME}"
}

get_make() {
    get_project "${MAKE_VERSION}" "${MAKE_URL}"
}

get_binutils() {
    get_project "${BINUTILS_VERSION}" "${BINUTILS_URL}"
}

get_gdb() {
    get_project "${GDB_VERSION}" "${GDB_URL}"

    # GDB depends on GMP and MPFR as well
    # Putting them in the GDB tree will build them with GDB
    if [[ ! -d "${SRCDIR}/${GDB_VERSION}/gmp" ]]; then
        cd "${SRCDIR}/${GDB_VERSION}"
        wget "${GMP_URL}"
        tar -xf "${GMP_VERSION}.tar.xz"
        rm "${GMP_VERSION}.tar.xz"
        mv "${GMP_VERSION}" "gmp"
    fi
    if [[ ! -d "${SRCDIR}/${GDB_VERSION}/mpfr" ]]; then
        cd "${SRCDIR}/${GDB_VERSION}"
        wget "${MPFR_URL}"
        tar -xf "${MPFR_VERSION}.tar.xz"
        rm "${MPFR_VERSION}.tar.xz"
        mv "${MPFR_VERSION}" "mpfr"
    fi
}

get_gcc() {
    get_project "${GCC_VERSION}" "${GCC_URL}"

    # Download all GCC dependencies (GMP, MPFR, MPC, and ISL), in case they aren't installed
    # Two of these dependencies are reused by GDB, but it will download its own copy
    # So that you can build GDB without GCC and vice versa
    cd "${SRCDIR}/${GCC_VERSION}"
    ./contrib/download_prerequisites

    # Fixup redzone for x86_64 targets
    patch_gcc
}

patch_gcc() {
    cd "${SRCDIR}/${GCC_VERSION}"
    if git apply --check "${REDZONE_PATCH}" > /dev/null 2>&1; then
        git apply "${REDZONE_PATCH}"
    fi
}

build_binutils() {
    local TARGET="${1}"
    if [[ -f "${OUTDIR}/bin/${TARGET}-as" ]]; then
        echo "${TARGET}-binutils already built"
        return
    fi

    get_binutils
    mkdir -p "${WORKDIR}/build-binutils-${TARGET}"
    cd "${WORKDIR}/build-binutils-${TARGET}" || exit
    "${SRCDIR}/${BINUTILS_VERSION}/configure" --target="${TARGET}" --prefix="${OUTDIR}" --with-sysroot --disable-nls --disable-werror
    make -j"$(nproc)"
    make install
}

build_gcc() {
    local TARGET="${1}"
    if [[ -f "${OUTDIR}/bin/${TARGET}-gcc" ]]; then
        echo "${TARGET}-gcc already built"
        return
    fi

    get_gcc
    mkdir -p "${WORKDIR}/build-gcc-${TARGET}"
    cd "${WORKDIR}/build-gcc-${TARGET}" || exit
    "${SRCDIR}/${GCC_VERSION}/configure" \
            --target="${TARGET}" --prefix="${OUTDIR}" --with-sysroot --enable-languages=c,c++ \
            --with-newlib=yes --without-headers --disable-nls --disable-hosted-libstdcxx \
            --disable-gcov --disable-libgomp --disable-libvtv --disable-libssp \
            --disable-threads --disable-libatomic --disable-libquadmath --disable-tls --disable-libgloss

    make -j"$(nproc)" all-gcc
    make -j"$(nproc)" all-target-libgcc
    make -j"$(nproc)" all-target-libstdc++-v3
    make install-gcc
    make install-target-libgcc
    make install-target-libstdc++-v3
}

build_gdb() {
    local TARGET="${1}"
    if [[ -f "${OUTDIR}/bin/${TARGET}-gdb" ]]; then
        echo "${TARGET}-gdb already built"
        return
    fi

    get_gdb
    mkdir -p "${WORKDIR}/build-gdb-${TARGET}"
    cd "${WORKDIR}/build-gdb-${TARGET}" || exit
    "${SRCDIR}/${GDB_VERSION}/configure" --target="${TARGET}" --prefix="${OUTDIR}" --enable-multilib --disable-nls --with-expat
    make -j"$(nproc)"
    make install
}

build_make() {
    if [[ -f "${OUTDIR}/bin/make" ]]; then
        echo "make already built"
        return
    fi

    get_make
    mkdir -p "${WORKDIR}/build-make"
    cd "${WORKDIR}/build-make" || exit
    "${SRCDIR}/${MAKE_VERSION}/configure" --prefix="${OUTDIR}" --disable-nls
    make -j"$(nproc)"
    make install
}

build_tools_for_target() {
    local TARGET="${1}"
    build_binutils "${TARGET}"
    build_gcc "${TARGET}"
    build_gdb "${TARGET}"
    echo "Done building ${TARGET}"
}

main() {
    setup_dirs
    get_make
    get_binutils
    get_gcc
    get_gdb
    build_make
    build_tools_for_target "x86_64-elf" & build_tools_for_target "aarch64-elf" & build_tools_for_target "riscv64-elf"
    echo "Done"
}

main "$@"
