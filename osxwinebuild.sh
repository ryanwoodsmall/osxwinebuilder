#!/bin/bash
#
# Compile and install Wine and many prerequisites in a self-contained directory.
#
# Copyright (C) 2009 Ryan Woodsmall <rwoodsmall@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#

# wine version
#   wine-X.Y.Z
export WINEVERSION="1.1.35"

# timestamp
export TIMESTAMP=$(date '+%Y%m%d%H%M%S')

# fail_and_exit
#   first function defined since it will be called if there are failures
function fail_and_exit {
        echo "${@} - exiting"
        exit 1
}

# wine dir
#   where everything lives - ~/wine by default
export WINEBASEDIR="${HOME}/wine"
#   make the base dir if it doesn't exist
if [ ! -d ${WINEBASEDIR} ] ; then
	mkdir -p ${WINEBASEDIR} || fail_and_exit "could not create ${WINEBASEDIR}"
fi

# installation path
#   ~/wine/wine-X.Y.Z
export WINEINSTALLPATH="${WINEBASEDIR}/wine-${WINEVERSION}"

# wine source path
#   ~/wine/source
export WINESOURCEPATH="${WINEBASEDIR}/source"
if [ ! -d ${WINESOURCEPATH} ] ; then
	mkdir -p ${WINESOURCEPATH} || fail_and_exit "could not create ${WINESOURCEPATH}"
fi

# build path
#   ~/wine/build
export WINEBUILDPATH="${WINEBASEDIR}/build"
if [ ! -d ${WINEBUILDPATH} ] ; then
	mkdir -p ${WINEBUILDPATH} || fail_and_exit "could not create ${WINEBUILDPATH}"
fi

# binary path
#   ~/wine/wine-X.Y.Z/bin
export WINEBINPATH="${WINEINSTALLPATH}/bin"

# include path
#   ~/wine/wine-X.Y.Z/include
export WINEINCLUDEPATH="${WINEINSTALLPATH}/include"

# lib path
#  ~/wine/wine-X.Y.Z/lib
export WINELIBPATH="${WINEINSTALLPATH}/lib"

# darwin/os x major version
#   10.6 = Darwin 10
#   10.5 = Darwin 9
#   ...
export DARWINMAJ=$(uname -r | awk -F. '{print $1}')

# 16-bit code flag
#   enable by default, disable on 10.5
#   XXX - should be checking Xcode version
#   2.x can build 16-bit code, works on 10.4, 10.5, 10.6
#   3.0,3.1 CANNOT build 16-bit code, work on 10.5+
#   3.2 can build 16-bit code, works only on 10.6
export WIN16FLAG="enable"
if [ ${DARWINMAJ} -eq 9 ] ; then
	export WIN16FLAG="disable"
fi

# os x min version and sdk settings
#   Mac OS X Tiger/10.4
#export OSXVERSIONMIN="10.4"
#   Mac OS X Leopard/10.5
#export OSXVERSIONMIN="10.5"
#   Mac OS X Snow Leopard/10.6
#export OSXVERSIONMIN="10.6"
#   only set SDK version and deployment target env vars if a min version is set
if [ ! -z "${OSXVERSIONMIN}" ] ; then
	if [ ${OSXVERSIONMIN} == "10.4" ] ; then
		export SDKADDITION="u"
	fi
	export OSXSDK="/Developer/SDKs/MacOSX${OSXVERSIONMIN}${SDKADDITION+${SDKADDITION}}.sdk"
	export MACOSX_DEPLOYMENT_TARGET=${OSXVERSIONMIN}
fi

# x11
export X11DIR="/usr/X11"
export X11BIN="${X11DIR}/bin"
export X11INC="${X11DIR}/include"
export X11LIB="${X11DIR}/lib"

# compiler and preprocessor flags
#   default
export CC="gcc"
export CXX="g++"
#   GCC 4.0
#export CC="gcc-4.0"
#export CXX="g++-4.0"
#   GCC 4.2
#export CC="gcc-4.2"
#export CXX="g++-4.2"
#   CLANG/LLVM
#export CC="/Developer/usr/bin/clang"
#export CC="/Developer/usr/bin/llvm-gcc-4.2"
#export CXX="/Developer/usr/bin/llvm-g++-4.2"
#   distcc
#export CC="distcc gcc"
#export CXX="distcc g++"
#   preprocessor/compiler flags
export CPPFLAGS="-I${WINEINCLUDEPATH} ${OSXSDK+-isysroot $OSXSDK} -I${X11INC}"
export CFLAGS="-g -arch i386 -m32 ${OSXSDK+-isysroot $OSXSDK} ${OSXVERSIONMIN+-mmacosx-version-min=$OSXVERSIONMIN} ${CPPFLAGS}"
export CXXFLAGS=${CFLAGS}

# linker flags
export LDFLAGS="-L${WINELIBPATH} ${OSXSDK+-isysroot $OSXSDK} -L${X11LIB} -framework CoreServices -lz -L${X11LIB} -lGL -lGLU"

# pkg-config config
#   system and stuff we build only
export PKG_CONFIG_PATH="${WINELIBPATH}/pkgconfig:/usr/lib/pkgconfig:${X11LIB}/pkgconfig"

# aclocal/automake
#   include custom, X11, other system stuff
export ACLOCAL="aclocal -I ${WINEINSTALLPATH}/share/aclocal -I ${X11DIR}/share/aclocal -I /usr/share/aclocal"

# make
export MAKE="make"
export MAKEJOBS=$((`sysctl machdep.cpu.core_count | awk -F: '{print $(NF)}' | tr -d " "`+1))
export CONCURRENTMAKE="${MAKE} -j${MAKEJOBS}"

# configure
export CONFIGURE="./configure"
export CONFIGURECOMMONPREFIX="--prefix=${WINEINSTALLPATH}"
export CONFIGURECOMMONLIBOPTS="--enable-shared=yes --enable-static=no"

# SHA-1 sum program
export SHA1SUM="openssl dgst -sha1"

# downloader program - curl's avail everywhere!
export CURL="curl"
export CURLOPTS="-kL"

# extract commands
export TARGZ="tar -zxvf"
export TARBZ2="tar -jxvf"

# path
#   pull out fink, macports, gentoo - what about homebrew?
export PATH=$(echo $PATH | tr ":" "\n" | egrep -v ^"(/opt/local|/sw|/opt/gentoo)" | xargs echo  | tr " " ":")
#   set install dir and X11 bin before everything else
export PATH="${WINEBINPATH}:${X11BIN}:${PATH}"

#
# helpers
#

#
# compiler_check
#   output a binary and run it
#
function compiler_check {
	if [ ! -d ${WINEBUILDPATH} ] ; then
		mkdir -p ${WINEBUILDPATH} || fail_and_exit "build directory ${WINEBUILDPATH} doesn't exist and cannot be created"
	fi
	cat > ${WINEBUILDPATH}/$$_compiler_check.c << EOF
#include <stdio.h>
int main(void)
{
  printf("hello\n");
  return(0);
}
EOF
	${CC} ${WINEBUILDPATH}/$$_compiler_check.c -o ${WINEBUILDPATH}/$$_compiler_check || fail_and_exit "compiler cannot ouput executables"
	${WINEBUILDPATH}/$$_compiler_check | grep hello >/dev/null 2>&1 || fail_and_exit "source compiled fine, but unexpected output was encountered"
	echo "compiler works fine for a simple test"
	rm -f ${WINEBUILDPATH}/$$_compiler_check.c ${WINEBUILDPATH}/$$_compiler_check
}

#
# get_file
#   receives a filename, directory and url
#
function get_file {
	FILE=${1}
	DIRECTORY=${2}
	URL=${3}
	if [ ! -d ${DIRECTORY} ] ; then
		mkdir -p ${DIRECTORY} || fail_and_exit "could not create directory ${DIRECTORY}"
	fi
	pushd . >/dev/null 2>&1
	cd ${DIRECTORY} || fail_and_exit "could not cd to ${DIRECTORY}"
	if [ ! -f ${FILE} ] ; then
		echo "downloading file ${URL} to ${DIRECTORY}/${FILE}"
		${CURL} ${CURLOPTS} -o ${FILE} ${URL}
	else
		echo "${DIRECTORY}/${FILE} already exists - not fetching"
		popd >/dev/null 2>&1
		return
	fi
	if [ $? != 0 ] ; then
		fail_and_exit "could not download ${URL}"
	else
		echo "successfully downloaded ${URL} to ${DIRECTORY}/${FILE}"
	fi
	popd >/dev/null 2>&1
} 

#
# check_sha1sum
#   receives a filename a SHA sum to compare
#
function check_sha1sum {
	FILE=${1}
	SHASUM=${2}
	if [ ! -e ${FILE} ] ; then
		fail_and_exit "${FILE} doesn't seem to exist"
	fi
	FILESUM=$(${SHA1SUM} < ${FILE})
	if [ "${SHASUM}x" != "${FILESUM}x" ] ; then
		fail_and_exit "failed to verify ${FILE}"
	else
		echo "succssfully verified ${FILE}"
	fi
}

#
# clean_source_dir
#   cleans up a source directory - receives base dir + source dir
#
function clean_source_dir {
	SOURCEDIR=${1}
	BASEDIR=${2}
	if [ -d ${BASEDIR}/${SOURCEDIR} ] ; then
		pushd . >/dev/null 2>&1
		echo "cleanning up ${BASEDIR}/${SOURCEDIR} for fresh compile"
		cd ${BASEDIR} || fail_and_exit "could not cd into ${BASEDIR}"
		rm -rf ${SOURCEDIR} || fail_and_exit "could not clean up ${BASEDIR}/${SOURCEDIR}"
		popd >/dev/null 2>&1
	fi
}

#
# extract_file
#   receives an extract command, a file and a directory
#
function extract_file {
	EXTRACTCMD=${1}
	EXTRACTFILE=${2}
	EXTRACTDIR=${3}
	echo "extracting ${EXTRACTFILE} to ${EXTRACTDIR} with '${EXTRACTCMD}'"
	if [ ! -d ${EXTRACTDIR} ] ; then
		mkdir -p ${EXTRACTDIR} || fail_and_exit "could not create ${EXTRACTDIR}"
	fi
	pushd . >/dev/null 2>&1
	cd ${EXTRACTDIR} || fail_and_exit "could not cd into ${EXTRACTDIR}"
	${EXTRACTCMD} ${EXTRACTFILE} || fail_and_exit "could not extract ${EXTRACTFILE}"
	echo "successfully extracted ${EXTRACTFILE}"
	popd >/dev/null 2>&1
}

#
# configure_package
#   receives a configure command and a directory in which to run it.
#
function configure_package {
	CONFIGURECMD=${1}
	SOURCEDIR=${2}
	if [ ! -d ${SOURCEDIR} ] ; then
		fail_and_exit "could not find ${SOURCEDIR}"
	fi
	echo "running '${CONFIGURECMD}' in ${SOURCEDIR}"
	pushd . >/dev/null 2>&1
	cd ${SOURCEDIR} || fail_and_exit "source directory ${SOURCEDIR} does not seem to exist"
	${CONFIGURECMD} || fail_and_exit "could not run configure command '${CONFIGURECMD}' in ${SOURCEDIR}"
	echo "successfully ran configure in ${SOURCEDIR}"
	popd >/dev/null 2>&1
}

#
# build_package
#   receives a build command line and a directory
#
function build_package {
	BUILDCMD=${1}
	BUILDDIR=${2}
	if [ ! -d ${BUILDDIR} ] ; then
		fail_and_exit "${BUILDDIR} does not exist"
	fi
	pushd . >/dev/null 2>&1
	cd ${BUILDDIR} || fail_and_exit "build directory ${BUILDDIR} does not seem to exist"
	${BUILDCMD} || fail_and_exit "could not run '${BUILDCMD}' in ${BUILDDIR}"
	echo "successfully ran '${BUILDCMD}' in ${BUILDDIR}"
	popd >/dev/null 2>&1
}

#
# install_package
#   receives an install command line and a directory to run it in
#
function install_package {
	INSTALLCMD=${1}
	INSTALLDIR=${2}
	if [ ! -d ${INSTALLDIR} ] ; then
		fail_and_exit "${INSTALLDIR} does not exist"
	fi
	echo "installing with '${INSTALLCMD}' in ${INSTALLDIR}"
	pushd . >/dev/null 2>&1
	cd ${INSTALLDIR} || fail_and_exit "directory ${INSTALLDIR} does not seem to exist"
	${INSTALLCMD}
	if [ $? != 0 ] ; then
		echo "some items may have failed to install! check above for errors."
	else
		echo "succesfully ran '${INSTALLCMD}' in ${INSTALLDIR}'"
	fi
	popd >/dev/null 2>&1
}

#
# package functions
#   common steps for (pretty much) each source build
#     clean
#     get
#     check
#     extract
#     configure
#     build
#     install
#

#
# pkg-config
#
PKGCONFIGVER="0.23"
PKGCONFIGFILE="pkg-config-${PKGCONFIGVER}.tar.gz"
PKGCONFIGURL="http://pkgconfig.freedesktop.org/releases/${PKGCONFIGFILE}"
PKGCONFIGSHA1SUM="b59dddd6b5320bd74c0f74b3339618a327096b2a"
PKGCONFIGDIR="pkg-config-${PKGCONFIGVER}"
function clean_pkg-config {
	clean_source_dir "${PKGCONFIGDIR}" "${WINEBUILDPATH}"
}
function get_pkg-config {
	get_file "${PKGCONFIGFILE}" "${WINESOURCEPATH}" "${PKGCONFIGURL}"
}
function check_pkg-config {
	check_sha1sum "${WINESOURCEPATH}/${PKGCONFIGFILE}" "${PKGCONFIGSHA1SUM}"
}
function extract_pkg-config {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${PKGCONFIGFILE}" "${WINEBUILDPATH}"
}
function configure_pkg-config {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}
function build_pkg-config {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}
function install_pkg-config {
	clean_pkg-config
	extract_pkg-config
	configure_pkg-config
	build_pkg-config
	install_package "${MAKE} install" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}

#
# gettext
#
GETTEXTVER="0.17"
GETTEXTFILE="gettext-${GETTEXTVER}.tar.gz"
GETTEXTURL="http://ftp.gnu.org/pub/gnu/gettext/${GETTEXTFILE}"
GETTEXTSHA1SUM="c51803d9f745f6ace36bd09c0486d5735ce399cf"
GETTEXTDIR="gettext-${GETTEXTVER}"
function clean_gettext {
	clean_source_dir "${GETTEXTDIR}" "${WINEBUILDPATH}"
}
function get_gettext {
	get_file "${GETTEXTFILE}" "${WINESOURCEPATH}" "${GETTEXTURL}"
}
function check_gettext {
	check_sha1sum "${WINESOURCEPATH}/${GETTEXTFILE}" "${GETTEXTSHA1SUM}"
}
function extract_gettext {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GETTEXTFILE}" "${WINEBUILDPATH}"
}
function configure_gettext {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-java --disable-native-java --without-emacs" "${WINEBUILDPATH}/${GETTEXTDIR}"
}
function build_gettext {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GETTEXTDIR}"
}
function install_gettext {
	clean_gettext
	extract_gettext
	configure_gettext
	build_gettext
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GETTEXTDIR}"
}

#
# jpeg
#
JPEGVER="7"
JPEGFILE="jpegsrc.v${JPEGVER}.tar.gz"
JPEGURL="http://www.ijg.org/files/${JPEGFILE}"
JPEGSHA1SUM="88cced0fc3dbdbc82115e1d08abce4e9d23a4b47"
JPEGDIR="jpeg-${JPEGVER}"
function clean_jpeg {
	clean_source_dir "${JPEGDIR}" "${WINEBUILDPATH}"
}
function get_jpeg {
	get_file "${JPEGFILE}" "${WINESOURCEPATH}" "${JPEGURL}"
}
function check_jpeg {
	check_sha1sum "${WINESOURCEPATH}/${JPEGFILE}" "${JPEGSHA1SUM}"
}
function extract_jpeg {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${JPEGFILE}" "${WINEBUILDPATH}"
}
function configure_jpeg {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${JPEGDIR}"
}
function build_jpeg {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${JPEGDIR}"
}
function install_jpeg {
	clean_jpeg
	extract_jpeg
	configure_jpeg
	build_jpeg
	install_package "${MAKE} install" "${WINEBUILDPATH}/${JPEGDIR}"
}

#
# jbigkit
#
JBIGKITVER="2.0"
JBIGKITMAJOR=$(echo ${JBIGKITVER} | awk -F\. '{print $1}')
JBIGKITFILE="jbigkit-${JBIGKITVER}.tar.gz"
JBIGKITURL="http://www.cl.cam.ac.uk/~mgk25/download/${JBIGKITFILE}"
JBIGKITSHA1SUM="cfb7d3121f02a74bfb229217858a0d149b6589ef"
JBIGKITDIR="jbigkit"
function clean_jbigkit {
	clean_source_dir "${JBIGKITDIR}" "${WINEBUILDPATH}"
}
function get_jbigkit {
	get_file "${JBIGKITFILE}" "${WINESOURCEPATH}" "${JBIGKITURL}"
}
function check_jbigkit {
	check_sha1sum "${WINESOURCEPATH}/${JBIGKITFILE}" "${JBIGKITSHA1SUM}"
}
function extract_jbigkit {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${JBIGKITFILE}" "${WINEBUILDPATH}"
}
function build_jbigkit {
	pushd . >/dev/null 2>&1
	echo "now building in ${WINEBUILDPATH}/${JBIGKITDIR}"
	cd ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig || fail_and_exit "could not cd to the JBIG source directory"
	JBIGKITOBJS=""
	for JBIGKITSRC in jbig jbig_ar ; do
		rm -f ${JBIGKITSRC}.o
		echo "${CC} ${CFLAGS} -O2 -Wall -I. -dynamic -ansi -pedantic -c ${JBIGKITSRC}.c -o ${JBIGKITSRC}.o"
		${CC} ${CFLAGS} -O2 -Wall -I. -dynamic -ansi -pedantic -c ${JBIGKITSRC}.c -o ${JBIGKITSRC}.o || fail_and_exit "failed building jbigkit's ${JBIGKITSRC}.c"
		JBIGKITOBJS+="${JBIGKITSRC}.o "
	done
	echo "creating libjbig shared library with libtool"
	libtool -dynamic -v -o libjbig.${JBIGKITVER}.dylib -install_name ${WINELIBPATH}/libjbig.${JBIGKITVER}.dylib -compatibility_version ${JBIGKITVER} -current_version ${JBIGKITVER} -lc ${JBIGKITOBJS} || fail_and_exit "failed to build jbigkit shared library"
	popd >/dev/null 2>&1
}
function install_jbigkit {
	clean_jbigkit
	extract_jbigkit
	build_jbigkit
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig || fail_and_exit "could not cd to the JBIG source directory"
	echo "installing libjbig shared library and symbolic links"
	install -m 755 libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.${JBIGKITVER}.dylib || fail_and_exit "could not install libjbig dynamic library"
	ln -s libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib || fail_and_exit "could not create libjbig symlink"
	ln -s libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.dylib || fail_and_exit "could not create libjbig symlink"
	echo "installing libjbig header files"
	for JBIGKITHDR in jbig.h jbig_ar.h ; do
		install -m 644 ${JBIGKITHDR} ${WINEINCLUDEPATH}/${JBIGKITHDR} || fail_and_exit "could not install JBIG header ${JBIGKITHDR}"
	done
	popd >/dev/null 2>&1
}

#
# tiff
#
TIFFVER="3.9.2"
TIFFFILE="tiff-${TIFFVER}.tar.gz"
TIFFURL="ftp://ftp.remotesensing.org/pub/libtiff/${TIFFFILE}"
TIFFSHA1SUM="5c054d31e350e53102221b7760c3700cf70b4327"
TIFFDIR="tiff-${TIFFVER}"
function clean_tiff {
	clean_source_dir "${TIFFDIR}" "${WINEBUILDPATH}"
}
function get_tiff {
	get_file "${TIFFFILE}" "${WINESOURCEPATH}" "${TIFFURL}"
}
function check_tiff {
	check_sha1sum "${WINESOURCEPATH}/${TIFFFILE}" "${TIFFSHA1SUM}"
}
function extract_tiff {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${TIFFFILE}" "${WINEBUILDPATH}"
}
function configure_tiff {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-jpeg-include-dir=${WINEINCLUDEPATH} --with-jbig-include-dir=${WINEINCLUDEPATH} --with-jpeg-lib-dir=${WINELIBPATH} --with-jbig-lib-dir=${WINELIBPATH} --with-apple-opengl-framework" "${WINEBUILDPATH}/${TIFFDIR}"
}
function build_tiff {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${TIFFDIR}"
}
function install_tiff {
	clean_tiff
	extract_tiff
	configure_tiff
	build_tiff
	install_package "${MAKE} install" "${WINEBUILDPATH}/${TIFFDIR}"
}

#
# libpng
#
LIBPNGVER="1.2.41"
LIBPNGFILE="libpng-${LIBPNGVER}.tar.gz"
LIBPNGURL="ftp://ftp.simplesystems.org/pub/libpng/png/src/${LIBPNGFILE}"
LIBPNGSHA1SUM="c9e5ea884d8f5551de328210ccfc386c60624366"
LIBPNGDIR="libpng-${LIBPNGVER}"
function clean_libpng {
	clean_source_dir "${LIBPNGDIR}" "${WINEBUILDPATH}"
}
function get_libpng {
	get_file "${LIBPNGFILE}" "${WINESOURCEPATH}" "${LIBPNGURL}"
}
function check_libpng {
	check_sha1sum "${WINESOURCEPATH}/${LIBPNGFILE}" "${LIBPNGSHA1SUM}"
}
function extract_libpng {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBPNGFILE}" "${WINEBUILDPATH}"
}
function configure_libpng {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBPNGDIR}"
}
function build_libpng {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBPNGDIR}"
}
function install_libpng {
	clean_libpng
	extract_libpng
	configure_libpng
	build_libpng
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBPNGDIR}"
}

#
# libxml
#
LIBXML2VER="2.7.6"
LIBXML2FILE="libxml2-${LIBXML2VER}.tar.gz"
LIBXML2URL="ftp://xmlsoft.org/libxml2/${LIBXML2FILE}"
LIBXML2SHA1SUM="b0f6bf8408e759ac4b8b9650005ee8adea911e1d"
LIBXML2DIR="libxml2-${LIBXML2VER}"
function clean_libxml2 {
	clean_source_dir "${LIBXML2DIR}" "${WINEBUILDPATH}"
}
function get_libxml2 {
	get_file "${LIBXML2FILE}" "${WINESOURCEPATH}" "${LIBXML2URL}"
}
function check_libxml2 {
	check_sha1sum "${WINESOURCEPATH}/${LIBXML2FILE}" "${LIBXML2SHA1SUM}"
}
function extract_libxml2 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBXML2FILE}" "${WINEBUILDPATH}"
}
function configure_libxml2 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --without-python" "${WINEBUILDPATH}/${LIBXML2DIR}"
}
function build_libxml2 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBXML2DIR}"
}
function install_libxml2 {
	clean_libxml2
	extract_libxml2
	configure_libxml2
	build_libxml2
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBXML2DIR}"
}

#
# libxslt
#
LIBXSLTVER="1.1.26"
LIBXSLTFILE="libxslt-${LIBXSLTVER}.tar.gz"
LIBXSLTURL="ftp://xmlsoft.org/libxml2/${LIBXSLTFILE}"
LIBXSLTSHA1SUM="69f74df8228b504a87e2b257c2d5238281c65154"
LIBXSLTDIR="libxslt-${LIBXSLTVER}"
function clean_libxslt {
	clean_source_dir "${LIBXSLTDIR}" "${WINEBUILDPATH}"
}
function get_libxslt {
	get_file "${LIBXSLTFILE}" "${WINESOURCEPATH}" "${LIBXSLTURL}"
}
function check_libxslt {
	check_sha1sum "${WINESOURCEPATH}/${LIBXSLTFILE}" "${LIBXSLTSHA1SUM}"
}
function extract_libxslt {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBXSLTFILE}" "${WINEBUILDPATH}"
}
function configure_libxslt {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libxml-prefix=${WINEINSTALLPATH} --without-crypto --without-python" "${WINEBUILDPATH}/${LIBXSLTDIR}"
}
function build_libxslt {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBXSLTDIR}"
}
function install_libxslt {
	clean_libxslt
	extract_libxslt
	configure_libxslt
	build_libxslt
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBXSLTDIR}"
}

#
# mpg123
#
# XXX - CFLAGS is *broken* - have to set everything in CC
MPG123VER="1.10.0"
MPG123FILE="mpg123-${MPG123VER}.tar.bz2"
MPG123URL="http://downloads.sourceforge.net/mpg123/${MPG123FILE}"
MPG123SHA1SUM="6a04d83a32aef1337cd18db26fc08552333bfa13"
MPG123DIR="mpg123-${MPG123VER}"
function clean_mpg123 {
	clean_source_dir "${MPG123DIR}" "${WINEBUILDPATH}"
}
function get_mpg123 {
	get_file "${MPG123FILE}" "${WINESOURCEPATH}" "${MPG123URL}"
}
function check_mpg123 {
	check_sha1sum "${WINESOURCEPATH}/${MPG123FILE}" "${MPG123SHA1SUM}"
}
function extract_mpg123 {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${MPG123FILE}" "${WINEBUILDPATH}"
}
function configure_mpg123 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-cpu=x86" "${WINEBUILDPATH}/${MPG123DIR}"
}
function build_mpg123 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${MPG123DIR}"
}
function install_mpg123 {
	export PRECC=${CC}
	export CC="${CC} -read_only_relocs suppress ${CFLAGS}"
	clean_mpg123
	extract_mpg123
	configure_mpg123
	build_mpg123
	install_package "${MAKE} install" "${WINEBUILDPATH}/${MPG123DIR}"
	export CC=${PRECC}
}

#
# gsm
#
# XXX - GSM is a HUGE HACK on OS X... and it doesn't appear to work.
GSMVER="1.0"
GSMMAJOR=$(echo ${GSMVER} | awk -F\. '{print $1}')
GSMPL="13"
GSMFILE="gsm-${GSMVER}.${GSMPL}.tar.gz"
#GSMURL="http://user.cs.tu-berlin.de/~jutta/gsm/${GSMFILE}"
GSMURL="http://ffmpeg.arrozcru.org/autobuilds/extra/sources/${GSMFILE}"
GSMSHA1SUM="668b0a180039a50d379b3d5a22e78da4b1d90afc"
GSMDIR="gsm-${GSMVER}-pl${GSMPL}"
function clean_gsm {
	clean_source_dir "${GSMDIR}" "${WINEBUILDPATH}"
}
function get_gsm {
	get_file "${GSMFILE}" "${WINESOURCEPATH}" "${GSMURL}"
}
function check_gsm {
	check_sha1sum "${WINESOURCEPATH}/${GSMFILE}" "${GSMSHA1SUM}"
}
function extract_gsm {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GSMFILE}" "${WINEBUILDPATH}"
}
function build_gsm {
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${GSMDIR} || fail_and_exit "could not cd to the GSM source directory"
	GSMOBJS=""
	for GSMSRC in add code debug decode long_term lpc preprocess rpe gsm_destroy gsm_decode gsm_encode gsm_explode gsm_implode gsm_create gsm_print gsm_option short_term table ; do
		rm -f src/${GSMSRC}.o
		GSMCC="${CC} ${CFLAGS} -dynamic -ansi -pedantic -c -O2 -Wall -DNeedFunctionPrototypes=1 -DSASR -DWAV49 -I./inc"
		echo "${GSMCC} src/${GSMSRC}.c -o src/${GSMSRC}.o"
		${GSMCC} src/${GSMSRC}.c -o src/${GSMSRC}.o || fail_and_exit "failed compiling GSM source file ${GSMSRC}.c"
		GSMOBJS+="src/${GSMSRC}.o "
	done
	rm -f lib/libgsm.${GSMVER}.${GSMPL}.dylib
	echo "creating libgsm dynamic library"
	libtool -dynamic -v -o lib/libgsm.${GSMVER}.${GSMPL}.dylib -install_name ${WINELIBPATH}/libgsm.${GSMVER}.${GSMPL}.dylib -compatibility_version ${GSMVER}.${GSMPL} -current_version ${GSMVER}.${GSMPL} -lc ${GSMOBJS} || fail_and_exit "failed creating GSM shared library"
	popd >/dev/null 2>&1
}
function install_gsm {
	clean_gsm
	extract_gsm
	build_gsm
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${GSMDIR} || fail_and_exit "could not cd to the GSM source directory"
	echo "installing libgsm shared library and symbolic links"
	install -m 755 lib/libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.${GSMVER}.${GSMPL}.dylib || fail_and_exit "could not install the libgsm dynamic library"
	ln -s libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib || fail_and_exit "could not create a libgsm symbolic link"
	ln -s libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.dylib || fail_and_exit "could not create a libgsm symbolic link"
	echo "installing libgsm header file"
	install -m 644 inc/gsm.h ${WINEINCLUDEPATH}/gsm.h || fail_and_exit "could not install the GSM gsm.h header file"
	popd >/dev/null 2>&1
}

#
# freetype
#
# XXX - CFLAGS issues with GCC 4.2+...
FREETYPEVER="2.3.11"
FREETYPEFILE="freetype-${FREETYPEVER}.tar.bz2"
FREETYPEURL="http://downloads.sourceforge.net/freetype/freetype2/${FREETYPEFILE}"
FREETYPESHA1SUM="693e1b4e423557975c2b2aca63559bc592533a0e"
FREETYPEDIR="freetype-${FREETYPEVER}"
function clean_freetype {
	clean_source_dir "${FREETYPEDIR}" "${WINEBUILDPATH}"
}
function get_freetype {
	get_file "${FREETYPEFILE}" "${WINESOURCEPATH}" "${FREETYPEURL}"
}
function check_freetype {
	check_sha1sum "${WINESOURCEPATH}/${FREETYPEFILE}" "${FREETYPESHA1SUM}"
}
function extract_freetype {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${FREETYPEFILE}" "${WINEBUILDPATH}"
}
function configure_freetype {
	# set subpixel rendering flag
	export FT_CONFIG_OPTION_SUBPIXEL_RENDERING=1
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${FREETYPEDIR}"
	echo "attempting to enable FreeType's subpixel rendering and bytecode interpretter in ${WINEBUILDPATH}/${FREETYPEDIR}"
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${FREETYPEDIR} || fail_and_exit "could not cd to ${FREETYPEDIR} for patching"
	# turn on nice but patented hinting
	if [ ! -f include/freetype/config/ftoption.h.unpatented_hinting ] ; then
		sed -i.unpatented_hinting \
			's#\#define TT_CONFIG_OPTION_UNPATENTED_HINTING#/\* \#define TT_CONFIG_OPTION_UNPATENTED_HINTING \*/#g' \
			include/freetype/config/ftoption.h || fail_and_exit "cound not unconfigure TT_CONFIG_OPTION_UNPATENTED_HINTING for freetype"
	fi
	if [ ! -f include/freetype/config/ftoption.h.bytecode_interpreter ] ; then
		sed -i.bytecode_interpreter \
			's#/\* \#define TT_CONFIG_OPTION_BYTECODE_INTERPRETER \*/#\#define TT_CONFIG_OPTION_BYTECODE_INTERPRETER#g' \
			include/freetype/config/ftoption.h || fail_and_exit "could not conifgure TT_CONFIG_OPTION_BYTECODE_INTERPRETER for freetype"
	fi
	if [ ! -f include/freetype/config/ftoption.h.subpixel_rendering ] ; then
		sed -i.subpixel_rendering \
			's#/\* \#define FT_CONFIG_OPTION_SUBPIXEL_RENDERING \*/#\#define FT_CONFIG_OPTION_SUBPIXEL_RENDERING#g' \
			include/freetype/config/ftoption.h || fail_and_exit "could not conifgure FT_CONFIG_OPTION_SUBPIXEL_RENDERING for freetype"
	fi
	echo "successfully configured and patched FreeType in ${WINEBUILDPATH}/${FREETYPEDIR}"
	popd >/dev/null 2>&1
}
function build_freetype {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${FREETYPEDIR}"
}
function install_freetype {
	export PRECC=${CC}
	export CC="${CC} ${CFLAGS}"
	clean_freetype
	extract_freetype
	configure_freetype
	build_freetype
	install_package "${MAKE} install" "${WINEBUILDPATH}/${FREETYPEDIR}"
	export CC=${PRECC}
}

#
# fontconfig
#
FONTCONFIGVER="2.8.0"
FONTCONFIGFILE="fontconfig-${FONTCONFIGVER}.tar.gz"
FONTCONFIGURL="http://fontconfig.org/release/${FONTCONFIGFILE}"
FONTCONFIGSHA1SUM="570fb55eb14f2c92a7b470b941e9d35dbfafa716"
FONTCONFIGDIR="fontconfig-${FONTCONFIGVER}"
function clean_fontconfig {
	clean_source_dir "${FONTCONFIGDIR}" "${WINEBUILDPATH}"
}
function get_fontconfig {
	get_file "${FONTCONFIGFILE}" "${WINESOURCEPATH}" "${FONTCONFIGURL}"
}
function check_fontconfig {
	check_sha1sum "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${FONTCONFIGSHA1SUM}"
}
function extract_fontconfig {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${WINEBUILDPATH}"
}
function configure_fontconfig {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-default-fonts=${X11LIB}/X11/fonts --with-confdir=${WINELIBPATH}/fontconfig --with-cache-dir=${X11DIR}/var/cache/fontconfig" "${WINEBUILDPATH}/${FONTCONFIGDIR}"
}
function build_fontconfig {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${FONTCONFIGDIR}"
}
function install_fontconfig {
	clean_fontconfig
	extract_fontconfig
	configure_fontconfig
	build_fontconfig
	install_package "${MAKE} install" "${WINEBUILDPATH}/${FONTCONFIGDIR}"
}

#
# lcms
#
LCMSVER="1.19"
LCMSFILE="lcms-${LCMSVER}.tar.gz"
LCMSURL="http://www.littlecms.com/${LCMSFILE}"
LCMSSHA1SUM="d5b075ccffc0068015f74f78e4bc39138bcfe2d4"
LCMSDIR="lcms-${LCMSVER}"
function clean_lcms {
	clean_source_dir "${LCMSDIR}" "${WINEBUILDPATH}"
}
function get_lcms {
	get_file "${LCMSFILE}" "${WINESOURCEPATH}" "${LCMSURL}"
}
function check_lcms {
	check_sha1sum "${WINESOURCEPATH}/${LCMSFILE}" "${LCMSSHA1SUM}"
}
function extract_lcms {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LCMSFILE}" "${WINEBUILDPATH}"
}
function configure_lcms {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --without-python --with-jpeg --with-tiff --with-zlib" "${WINEBUILDPATH}/${LCMSDIR}"
}
function build_lcms {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LCMSDIR}"
}
function install_lcms {
	clean_lcms
	extract_lcms
	configure_lcms
	build_lcms
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LCMSDIR}"
}

#
# lzo
#
# XXX - broken CFLAGS, bundle w/CC
LZOVER="2.03"
LZOFILE="lzo-${LZOVER}.tar.gz"
LZOURL="http://www.oberhumer.com/opensource/lzo/download/${LZOFILE}"
LZOSHA1SUM="135a50699296e853362a3d11b9f872c74c8b8c5a"
LZODIR="lzo-${LZOVER}"
function clean_lzo {
	clean_source_dir "${LZODIR}" "${WINEBUILDPATH}"
}
function get_lzo {
	get_file "${LZOFILE}" "${WINESOURCEPATH}" "${LZOURL}"
}
function check_lzo {
	check_sha1sum "${WINESOURCEPATH}/${LZOFILE}" "${LZOSHA1SUM}"
}
function extract_lzo {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LZOFILE}" "${WINEBUILDPATH}"
}
function configure_lzo {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-asm" "${WINEBUILDPATH}/${LZODIR}"
}
function build_lzo {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LZODIR}"
}
function install_lzo {
	export PRECC=${CC}
	export CC="${CC} ${CFLAGS}"
	clean_lzo
	extract_lzo
	configure_lzo
	build_lzo
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LZODIR}"
	export CC=${PRECC}
}

#
# libgpg-error
#
LIBGPGERRORVER="1.7"
LIBGPGERRORFILE="libgpg-error-${LIBGPGERRORVER}.tar.bz2"
LIBGPGERRORURL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${LIBGPGERRORFILE}"
LIBGPGERRORSHA1SUM="bf8c6babe1e28cae7dd6374ca24ddcc42d57e902"
LIBGPGERRORDIR="libgpg-error-${LIBGPGERRORVER}"
function clean_libgpg-error {
	clean_source_dir "${LIBGPGERRORDIR}" "${WINEBUILDPATH}"
}
function get_libgpg-error {
	get_file "${LIBGPGERRORFILE}" "${WINESOURCEPATH}" "${LIBGPGERRORURL}"
}
function check_libgpg-error {
	check_sha1sum "${WINESOURCEPATH}/${LIBGPGERRORFILE}" "${LIBGPGERRORSHA1SUM}"
}
function extract_libgpg-error {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGPGERRORFILE}" "${WINEBUILDPATH}"
}
function configure_libgpg-error {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}
function build_libgpg-error {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}
function install_libgpg-error {
	clean_libgpg-error
	extract_libgpg-error
	configure_libgpg-error
	build_libgpg-error
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}

#
# libgcrypt
#
LIBGCRYPTVER="1.4.5"
LIBGCRYPTFILE="libgcrypt-${LIBGCRYPTVER}.tar.bz2"
LIBGCRYPTURL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/${LIBGCRYPTFILE}"
LIBGCRYPTSHA1SUM="ef7ecbd3a03a7978094366bcd1257b3654608d28"
LIBGCRYPTDIR="libgcrypt-${LIBGCRYPTVER}"
function clean_libgcrypt {
	clean_source_dir "${LIBGCRYPTDIR}" "${WINEBUILDPATH}"
}
function get_libgcrypt {
	get_file "${LIBGCRYPTFILE}" "${WINESOURCEPATH}" "${LIBGCRYPTURL}"
}
function check_libgcrypt {
	check_sha1sum "${WINESOURCEPATH}/${LIBGCRYPTFILE}" "${LIBGCRYPTSHA1SUM}"
}
function extract_libgcrypt {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGCRYPTFILE}" "${WINEBUILDPATH}"
}
function configure_libgcrypt {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-gpg-error-prefix=${WINEINSTALLPATH}" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
}
function build_libgcrypt {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
}
function install_libgcrypt {
	clean_libgcrypt
	extract_libgcrypt
	configure_libgcrypt
	build_libgcrypt
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
}

#
# gnutls
#
GNUTLSVER="2.8.5"
GNUTLSFILE="gnutls-${GNUTLSVER}.tar.bz2"
GNUTLSURL="ftp://ftp.gnu.org/pub/gnu/gnutls/${GNUTLSFILE}"
GNUTLSSHA1SUM="5121c52efd4718ad3d8b641d28343b0c6abaa571"
GNUTLSDIR="gnutls-${GNUTLSVER}"
function clean_gnutls {
	clean_source_dir "${GNUTLSDIR}" "${WINEBUILDPATH}"
}
function get_gnutls {
	get_file "${GNUTLSFILE}" "${WINESOURCEPATH}" "${GNUTLSURL}"
}
function check_gnutls {
	check_sha1sum "${WINESOURCEPATH}/${GNUTLSFILE}" "${GNUTLSSHA1SUM}"
}
function extract_gnutls {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GNUTLSFILE}" "${WINEBUILDPATH}"
}
function configure_gnutls {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libgcrypt-prefix=${WINEINSTALLPATH} --with-included-libcfg --with-included-libtasn1 --with-lzo" "${WINEBUILDPATH}/${GNUTLSDIR}"
}
function build_gnutls {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GNUTLSDIR}"
}
function install_gnutls {
	clean_gnutls
	extract_gnutls
	configure_gnutls
	build_gnutls
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GNUTLSDIR}"
}

#
# unixodbc
#
UNIXODBCVER="2.2.14"
UNIXODBCFILE="unixODBC-${UNIXODBCVER}.tar.gz"
UNIXODBCURL="http://www.unixodbc.org/${UNIXODBCFILE}"
UNIXODBCSHA1SUM="ab18464c83d30d7b38b8bb58e1dd01e3ec211488"
UNIXODBCDIR="unixODBC-${UNIXODBCVER}"
function clean_unixodbc {
	clean_source_dir "${UNIXODBCDIR}" "${WINEBUILDPATH}"
}
function get_unixodbc {
	get_file "${UNIXODBCFILE}" "${WINESOURCEPATH}" "${UNIXODBCURL}"
}
function check_unixodbc {
	check_sha1sum "${WINESOURCEPATH}/${UNIXODBCFILE}" "${UNIXODBCSHA1SUM}"
}
function extract_unixodbc {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${UNIXODBCFILE}" "${WINEBUILDPATH}"
}
function configure_unixodbc {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --enable-gui=no" "${WINEBUILDPATH}/${UNIXODBCDIR}"
}
function build_unixodbc {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${UNIXODBCDIR}"
}
function install_unixodbc {
	clean_unixodbc
	extract_unixodbc
	configure_unixodbc
	build_unixodbc
	install_package "${MAKE} install" "${WINEBUILDPATH}/${UNIXODBCDIR}"
}

#
# libexif
#
LIBEXIFVER="0.6.19"
LIBEXIFFILE="libexif-${LIBEXIFVER}.tar.bz2"
LIBEXIFURL="http://downloads.sourceforge.net/libexif/${LIBEXIFFILE}"
LIBEXIFSHA1SUM="820f07ff12a8cc720a6597d46277f01498c8aba4"
LIBEXIFDIR="libexif-${LIBEXIFVER}"
function clean_libexif {
	clean_source_dir "${LIBEXIFDIR}" "${WINEBUILDPATH}"
}
function get_libexif {
	get_file "${LIBEXIFFILE}" "${WINESOURCEPATH}" "${LIBEXIFURL}"
}
function check_libexif {
	check_sha1sum "${WINESOURCEPATH}/${LIBEXIFFILE}" "${LIBEXIFSHA1SUM}"
}
function extract_libexif {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBEXIFFILE}" "${WINEBUILDPATH}"
}
function configure_libexif {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBEXIFDIR}"
}
function build_libexif {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBEXIFDIR}"
}
function install_libexif {
	clean_libexif
	extract_libexif
	configure_libexif
	build_libexif
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBEXIFDIR}"
}

#
# libusb
#
LIBUSBVER="0.1.12"
LIBUSBFILE="libusb-${LIBUSBVER}.tar.gz"
LIBUSBURL="http://downloads.sourceforge.net/libusb/libusb-0.1%20%28LEGACY%29/${LIBUSBFILE}"
LIBUSBSHA1SUM="599a5168590f66bc6f1f9a299579fd8500614807"
LIBUSBDIR="libusb-${LIBUSBVER}"
function clean_libusb {
	clean_source_dir "${LIBUSBDIR}" "${WINEBUILDPATH}"
}
function get_libusb {
	get_file "${LIBUSBFILE}" "${WINESOURCEPATH}" "${LIBUSBURL}"
}
function check_libusb {
	check_sha1sum "${WINESOURCEPATH}/${LIBUSBFILE}" "${LIBUSBSHA1SUM}"
}
function extract_libusb {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBUSBFILE}" "${WINEBUILDPATH}"
}
function configure_libusb {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBUSBDIR}"
}
function build_libusb {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBUSBDIR}"
}
function install_libusb {
	clean_libusb
	extract_libusb
	configure_libusb
	build_libusb
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBUSBDIR}"
}

#
# libgphoto2
#
LIBGPHOTO2VER="2.4.7"
LIBGPHOTO2FILE="libgphoto2-${LIBGPHOTO2VER}.tar.bz2"
LIBGPHOTO2URL="http://downloads.sourceforge.net/gphoto/libgphoto/${LIBGPHOTO2FILE}"
LIBGPHOTO2SHA1SUM="f91aef06204f3b1b0f3e07facba452881bedc2e1"
LIBGPHOTO2DIR="libgphoto2-${LIBGPHOTO2VER}"
function clean_libgphoto2 {
	clean_source_dir "${LIBGPHOTO2DIR}" "${WINEBUILDPATH}"
}
function get_libgphoto2 {
	get_file "${LIBGPHOTO2FILE}" "${WINESOURCEPATH}" "${LIBGPHOTO2URL}"
}
function check_libgphoto2 {
	check_sha1sum "${WINESOURCEPATH}/${LIBGPHOTO2FILE}" "${LIBGPHOTO2SHA1SUM}"
}
function extract_libgphoto2 {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGPHOTO2FILE}" "${WINEBUILDPATH}"
}
function configure_libgphoto2 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libexif=auto" "${WINEBUILDPATH}/${LIBGPHOTO2DIR}"
}
function build_libgphoto2 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGPHOTO2DIR}"
}
function install_libgphoto2 {
	clean_libgphoto2
	extract_libgphoto2
	configure_libgphoto2
	build_libgphoto2
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGPHOTO2DIR}"
}

#
# sane-backends
#
SANEBACKENDSVER="1.0.20"
SANEBACKENDSFILE="sane-backends-${SANEBACKENDSVER}.tar.gz"
SANEBACKENDSURL="ftp://ftp.sane-project.org/pub/sane/sane-backends-1.0.20/${SANEBACKENDSFILE}"
SANEBACKENDSSHA1SUM="3b4d2ecde8be404bb44269771cf5dc6e4c10b086"
SANEBACKENDSDIR="sane-backends-${SANEBACKENDSVER}"
function clean_sane-backends {
	clean_source_dir "${SANEBACKENDSDIR}" "${WINEBUILDPATH}"
}
function get_sane-backends {
	get_file "${SANEBACKENDSFILE}" "${WINESOURCEPATH}" "${SANEBACKENDSURL}"
}
function check_sane-backends {
	check_sha1sum "${WINESOURCEPATH}/${SANEBACKENDSFILE}" "${SANEBACKENDSSHA1SUM}"
}
function extract_sane-backends {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${SANEBACKENDSFILE}" "${WINEBUILDPATH}"
}
function configure_sane-backends {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-gphoto2" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
}
function build_sane-backends {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
}
function install_sane-backends {
	clean_sane-backends
	extract_sane-backends
	configure_sane-backends
	build_sane-backends
	install_package "${MAKE} install" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
}

#
# cabextract
#
CABEXTRACTVER="1.2"
CABEXTRACTFILE="cabextract-${CABEXTRACTVER}.tar.gz"
CABEXTRACTURL="http://www.cabextract.org.uk/${CABEXTRACTFILE}"
CABEXTRACTSHA1SUM="871b3db4bc2629eb5726659c147aecea1af6a6d0"
CABEXTRACTDIR="cabextract-${CABEXTRACTVER}"
function clean_cabextract {
	clean_source_dir "${CABEXTRACTDIR}" "${WINEBUILDPATH}"
}
function get_cabextract {
	get_file "${CABEXTRACTFILE}" "${WINESOURCEPATH}" "${CABEXTRACTURL}"
}
function check_cabextract {
	check_sha1sum "${WINESOURCEPATH}/${CABEXTRACTFILE}" "${CABEXTRACTSHA1SUM}"
}
function extract_cabextract {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${CABEXTRACTFILE}" "${WINEBUILDPATH}"
}
function configure_cabextract {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX}" "${WINEBUILDPATH}/${CABEXTRACTDIR}"
}
function build_cabextract {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${CABEXTRACTDIR}"
}
function install_cabextract {
	clean_cabextract
	extract_cabextract
	configure_cabextract
	build_cabextract
	install_package "${MAKE} install" "${WINEBUILDPATH}/${CABEXTRACTDIR}"
}

#
# gecko
#
GECKOVERSION="1.0.0"
GECKOFILE="wine_gecko-${GECKOVERSION}-x86.cab"
GECKOURL="http://downloads.sourceforge.net/wine/${GECKOFILE}"
GECKOSHA1SUM="afa22c52bca4ca77dcb9edb3c9936eb23793de01"
function get_gecko {
	get_file "${GECKOFILE}" "${WINESOURCEPATH}" "${GECKOURL}"
}
function check_gecko {
	check_sha1sum "${WINESOURCEPATH}/${GECKOFILE}" "${GECKOSHA1SUM}"
}
function install_gecko {
	if [ ! -d  "${WINEINSTALLPATH}/share/wine/gecko" ] ; then
		mkdir -p ${WINEINSTALLPATH}/share/wine/gecko || fail_and_exit "could not create directory for Gecko installation"
	fi
	echo "installing ${GECKOFILE} into ${WINEINSTALLPATH}/share/wine/gecko"
	install -m 644 ${WINESOURCEPATH}/${GECKOFILE} ${WINEINSTALLPATH}/share/wine/gecko/${GECKOFILE} || fail_and_exit "could not put the Wine Gecko cab in the proper location"
}

#
# winetricks
#
# XXX - get latest version, install as exectuable!
WINETRICKSFILE="winetricks"
WINETRICKSURL="http://www.kegel.com/wine/${WINETRICKSFILE}"
function get_winetricks {
	# always get winetricks
	pushd . >/dev/null 2>&1
	cd ${WINESOURCEPATH} || fail_and_exit "could not cd to the Wine source repo path"
	echo "downloading ${WINETRICKSURL} to ${WINESOURCEPATH}/${WINETRICKSFILE}"
	${CURL} ${CURLOPTS} -o ${WINETRICKSFILE}.${TIMESTAMP} ${WINETRICKSURL}
	if [ $? == 0 ] ; then
		if [ -f ${WINETRICKSFILE} ] ; then
			mv ${WINETRICKSFILE} ${WINETRICKSFILE}.PRE-${TIMESTAMP}
		fi
		mv ${WINETRICKSFILE}.${TIMESTAMP} ${WINETRICKSFILE}
	fi
	popd >/dev/null 2>&1
}
function install_winetricks {
	if [ -f "${WINESOURCEPATH}/${WINETRICKSFILE}" ] ; then
		echo "installing ${WINETRICKSFILE} into ${WINEBINPATH}"
		install -m 755 ${WINESOURCEPATH}/${WINETRICKSFILE} ${WINEBINPATH}/${WINETRICKSFILE} || echo "could not install install winetricks to ${WINEBINPATH}/${WINETRICKSFILE} - not fatal, install manually"
	fi
}

#
# build wine, finally
#
WINEVER=${WINEVERSION}
WINEFILE="wine-${WINEVER}.tar.bz2"
WINEURL="http://ibiblio.org/pub/linux/system/emulators/wine/${WINEFILE}"
WINESHA1SUM="9e5fefe469ea104a77b1aaaf56d99c89e905e4b4"
WINEDIR="wine-${WINEVER}"
function clean_wine {
	clean_source_dir "${WINEDIR}" "${WINEBUILDPATH}"
}
function get_wine {
	get_file "${WINEFILE}" "${WINESOURCEPATH}" "${WINEURL}"
}
function check_wine {
	check_sha1sum "${WINESOURCEPATH}/${WINEFILE}" "${WINESHA1SUM}"
}
function extract_wine {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${WINEFILE}" "${WINEBUILDPATH}"
}
function configure_wine {
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${WINEDIR} || fail_and_exit "could not cd into ${WINEBUILDPATH}/${WINEDIR} to configure Wine"
	echo "now configuring wine in ${WINEBUILDPATH}/${WINEDIR}"
	${CONFIGURE} ${CONFIGURECOMMONPREFIX} \
		--verbose \
		--${WIN16FLAG}-win16 \
		--disable-win64 \
		--without-capi \
		--without-hal \
		--with-cms \
		--with-coreaudio \
		--with-cups \
		--with-curses \
		--with-fontconfig \
		--with-freetype \
		--with-glu \
		--with-gnutls \
		--with-gphoto \
		--with-gsm \
		--with-jpeg \
		--with-ldap \
		--with-mpg123 \
		--with-openal \
		--with-opengl \
		--with-openssl \
		--with-png \
		--with-pthread \
		--with-sane \
		--with-xml \
		--with-xslt \
		--with-x \
		--x-includes=${X11INC} \
		--x-libraries=${X11LIB} || fail_and_exit "could not configure wine in ${WINEBUILDPATH}/${WINEDIR}"
	echo "successfully configured wine in ${WINEBUILDPATH}/${WINEDIR}"
	popd >/dev/null 2>&1
}
function depend_wine {
	build_package "${MAKE} depend" "${WINEBUILDPATH}/${WINEDIR}"
}
function build_wine {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${WINEDIR}"
}
function install_wine {
	clean_wine
	extract_wine
	configure_wine
	depend_wine
	build_wine
	install_package "${MAKE} install" "${WINEBUILDPATH}/${WINEDIR}"
}

#
# get_sources
#   fetches all source packages
#
function get_sources {
	get_pkg-config
	get_gettext
	get_jpeg
	get_jbigkit
	get_tiff
	get_libpng
	get_libxml2
	get_libxslt
	get_mpg123
	get_gsm
	get_freetype
	get_fontconfig
	get_lcms
	get_lzo
	get_libgpg-error
	get_libgcrypt
	get_gnutls
	get_unixodbc
	get_libexif
	get_libusb
	get_libgphoto2
	get_sane-backends
	get_cabextract
	get_gecko
	get_winetricks
	get_wine
}

#
# check_sources
#   checks all source SHA-1 sums
#
function check_sources {
	check_pkg-config
	check_gettext
	check_jpeg
	check_jbigkit
	check_tiff
	check_libpng
	check_libxml2
	check_libxslt
	check_mpg123
	check_gsm
	check_freetype
	check_fontconfig
	check_lcms
	check_lzo
	check_libgpg-error
	check_libgcrypt
	check_gnutls
	check_unixodbc
	check_libexif
	check_libusb
	check_libgphoto2
	check_sane-backends
	check_cabextract
	check_gecko
	check_wine
}

#
# install prereqs
#   extracts, builds and installs prereqs
#
function install_prereqs {
	install_pkg-config
	install_gettext
	install_jpeg
	install_jbigkit
	install_tiff
	install_libpng
	install_libxml2
	install_libxslt
	install_mpg123
	install_gsm
	install_freetype
	install_fontconfig
	install_lcms
	install_lzo
	install_libgpg-error
	install_libgcrypt
	install_gnutls
	install_libexif
	install_libusb
	install_libgphoto2
	install_sane-backends
	install_unixodbc
	install_cabextract
	install_winetricks
	install_gecko
}


#
# now that our helper functions are done, run through the actual install
#

# move the install dir out of the way if it exists
if [ -d ${WINEINSTALLPATH} ] ; then
	mv ${WINEINSTALLPATH}{,.PRE-${TIMESTAMP}}
fi

# check compiler before anything else
compiler_check

# get all the sources we'll be using
get_sources

# check source SHA-1 sums
check_sources

# install requirements
install_prereqs

# install wine, for real, really really real
install_wine
