#!/bin/bash
#
# Compile and install Wine and many prerequisites in a self-contained directory.
#
# Copyright (C) 2009,2010,2011,2012 Ryan Woodsmall <rwoodsmall@gmail.com>
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

# fail_and_exit
#   first function defined since it will be called if there are failures
function fail_and_exit {
	echo "${@} - exiting"
	exit 1
}

# usage
#   defined early; may be called if "--help" or a bunk option is passed
function usage {
	echo "usage: $(basename ${0}) [--help] [--stable] [--devel] [--crossover] [--cxgames] [--no-clean-prefix] [--no-clean-source] [--no-rebuild] [--no-reconfigure]"
	echo ""
	echo "  Informational option(s):"
	echo "    --help: display this help message"
	echo ""
	echo "  Build type options (mutually exclusive):"
	echo "    --devel: build the development version of Wine (default)"
	echo "    --stable: build the stable version of Wine"
	echo "    --crossover: build Wine using CrossOver sources"
	echo "    --cxgames: build Wine using CrossOver Games sources"
	echo ""
	echo "  Common build options:"
	echo "    --no-clean-prefix: do not move and create a new prefix if one already exists"
	echo "    --no-clean-source: do not remove/extract source if already done"
	echo "    --no-rebuild: do not rebuild packages, just reinstall"
	echo "    --no-reconfigure: do not re-run 'configure' for any packages"
	echo ""
}

# options
#   set Wine build type to zero, handle below using flags
BUILDSTABLE=0
BUILDDEVEL=0
BUILDCROSSOVER=0
BUILDCXGAMES=0
#   use this flag to track which Wine we're building
BUILDFLAG=0
#   we remove and rebuild everything in a new prefix by default
NOCLEANPREFIX=0
NOCLEANSOURCE=0
NOREBUILD=0
NORECONFIGURE=0
#   cycle through options and set appropriate vars
if [ ${#} -gt 0 ] ; then
	until [ -z ${1} ] ; do
		case ${1} in
			--stable)
				if [ ${BUILDFLAG} -ne 1 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+1))
				fi
				shift ;;
			--devel)
				if [ ${BUILDFLAG} -ne 10 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+10))
				fi
				shift ;;
			--crossover)
				if [ ${BUILDFLAG} -ne 100 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+100))
				fi
				shift ;;
			--cxgames)
				if [ ${BUILDFLAG} -ne 1000 ] ; then
					BUILDFLAG=$((${BUILDFLAG}+1000))
				fi
				shift ;;
			--no-clean-prefix)
				NOCLEANPREFIX=1
				echo "found --no-clean-prefix option, will install to existing prefix if it exists" ; shift ;;
			--no-clean-source)
				NOCLEANSOURCE=1
				echo "found --no-clean-source option, will not remove/rextract existing source directories" ; shift ;;
			--no-rebuild)
				NOREBUILD=1
				echo "found --no-rebuild option, will not re-run 'make' on existing source directories" ; shift ;;
			--no-reconfigure)
				NORECONFIGURE=1
				echo "found --no-reconfigure option, will not re-run 'configure' on existing source directories" ; shift ;;
			--help)
				usage ; exit 0 ;;
			*)
				usage ; exit 1 ;;
		esac
	done
fi

# wine version
#   a tag we'll use later
WINETAG=""
#   stable
WINESTABLEVERSION="1.4"
WINESTABLESHA1SUM="ce5d56b9b949c01dde663ab39739ffcfb41a73c4"
#   devel
WINEDEVELVERSION="1.5.5"
WINEDEVELSHA1SUM="523c15277995f4edac539b333ab980b5b208f8d0"
#   CrossOver Wine
CROSSOVERVERSION="10.1.0"
CROSSOVERSHA1SUM="8c934d40706249bfb82a82325dfe13b05fa5ebac"
#   CrossOver Games Wine
CXGAMESVERSION="10.1.1"
CXGAMESSHA1SUM="44404284d82843fb4f01a5e530735b2b1f8927ff"

# check our build flag and pick the right version
if [ ${BUILDFLAG} -eq 1 ] ; then
	BUILDSTABLE=1
	WINEVERSION="${WINESTABLEVERSION}"
	WINESHA1SUM="${WINESTABLESHA1SUM}"
	WINETAG="Wine ${WINEVERSION}"
	echo "found --stable option, will build Wine stable version"
elif [ ${BUILDFLAG} -eq 10 ] || [ ${BUILDFLAG} -eq 0 ] ; then
	BUILDDEVEL=1
	WINEVERSION="${WINEDEVELVERSION}"
	WINESHA1SUM="${WINEDEVELSHA1SUM}"
	WINETAG="Wine ${WINEVERSION}"
	echo "found --devel option or no build options, will build Wine devel version"
elif [ ${BUILDFLAG} -eq 100 ] ; then
	BUILDCROSSOVER=1
	WINEVERSION="${CROSSOVERVERSION}"
	WINESHA1SUM="${CROSSOVERSHA1SUM}"
	WINETAG="CrossOver Wine ${WINEVERSION}"
	echo "found --crossover option, will build Wine from CrossOver sources"
elif [ ${BUILDFLAG} -eq 1000 ] ; then
	BUILDCXGAMES=1
	WINEVERSION="${CXGAMESVERSION}"
	WINESHA1SUM="${CXGAMESSHA1SUM}"
	WINETAG="CrossOver Games Wine ${WINEVERSION}"
	echo "found --cxgames option, will build Wine from CrossOver Games sources"
else
	BUILDSTABLE=0
	BUILDDEVEL=1
	BUILDCROSSOVER=0
	BUILDCXGAMES=0
	WINEVERSION="${WINEDEVELVERSION}"
	WINESHA1SUM="${WINEDEVELSHA1SUM}"
	WINETAG="Wine ${WINEVERSION}"
	echo "found multiple build types or no specified build type, defaulting to Wine devel"
fi

# what are we building?
echo "building ${WINETAG}"

# set our file name, Wine source directory name and URL correctly
if [ ${BUILDSTABLE} -eq 1 ] || [ ${BUILDDEVEL} -eq 1 ] ; then
	WINEFILE="wine-${WINEVERSION}.tar.bz2"
	WINEURL="http://downloads.sourceforge.net/wine/${WINEFILE}"
	WINEDIR="wine-${WINEVERSION}"
elif [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
	if [ ${BUILDCROSSOVER} -eq 1 ] ; then
		WINEFILE="crossover-sources-${WINEVERSION}.tar.gz"
	elif [ ${BUILDCXGAMES} -eq 1 ] ; then
		WINEFILE="crossover-games-sources-${WINEVERSION}.tar.gz"
	fi
	WINEURL="http://media.codeweavers.com/pub/crossover/source/${WINEFILE}"
	WINEDIR="wine"
fi

# timestamp
export TIMESTAMP=$(date '+%Y%m%d%H%M%S')

# wine dir
#   where everything lives - ~/wine by default
export WINEBASEDIR="${HOME}/wine"
#   make the base dir if it doesn't exist
if [ ! -d ${WINEBASEDIR} ] ; then
	mkdir -p ${WINEBASEDIR} || fail_and_exit "could not create ${WINEBASEDIR}"
fi

# installation path
#   ~/wine/wine-X.Y.Z for standard Wine
#   if we're doing a CrossOver build, set the proper directory name
WINEINSTALLDIRPREPEND=""
if [ ${BUILDCROSSOVER} -eq 1 ] ; then
	WINEINSTALLDIRPREPEND="crossover-"
elif [ ${BUILDCXGAMES} -eq 1 ] ; then
	WINEINSTALLDIRPREPEND="crossover-games-"
fi
export WINEINSTALLPATH="${WINEBASEDIR}/${WINEINSTALLDIRPREPEND+${WINEINSTALLDIRPREPEND}}wine-${WINEVERSION}"

echo "${WINETAG} will be installed into ${WINEINSTALLPATH}"

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
#   10.7 = Darwin 11
#   10.6 = Darwin 10
#   10.5 = Darwin 9
#   ...
export DARWINMAJ=$(uname -r | awk -F. '{print $1}')

# 16-bit code flag
#   enable by default, disable on 10.5
#   XXX - should be checking Xcode version
#   2.x can build 16-bit code, works on 10.4, 10.5, 10.6
#   3.0,3.1 CANNOT build 16-bit code, work on 10.5+
#     XXX - patched ld/ld64 on 10.5 can be used
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
#   these need to be changed for Xquartz and the like...
#   default is to use OS-provided /usr/X11
export DEFAULTX11DIR="/usr/X11"
export X11DIR="${DEFAULTX11DIR}"
# check for XQuartz in /opt/X11 on 10.6+
if [ ${DARWINMAJ} -ge 10 ] ; then
	# check for the XQuartz launchd entry
	launchctl list | grep -i startx | grep -i xquartz >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo "XQuartz launchd startup found, checking for installation"
		# check that directory /opt/X11 exists and use it
		if [ -d /opt/X11 ] ; then
			echo "using XQuartz installed in /opt/X11"
			export X11DIR="/opt/X11"
		else
			echo "XQuartz launchd startup found, but no /opt/X11; reinstall XQuartz?"
		fi
	else
		echo "no XQuartz launchd startup found, assuming system X11 in ${DEFAULTX11DIR}"
	fi
fi
echo "X11 installation set to: \$X11DIR = ${X11DIR}"
export X11BIN="${X11DIR}/bin"
export X11INC="${X11DIR}/include"
export X11LIB="${X11DIR}/lib"

# compiler and preprocessor flags
#   default - set to GCC
: ${CC:="gcc"}
: ${CXX:="g++"}
export CC
export CXX
echo "C compiler set to: \$CC = \"${CC}\""
echo "C++ compiler set to: \$CXX = \"${CXX}\""
#   preprocessor/compiler flags
export CPPFLAGS="-I${WINEINCLUDEPATH} ${OSXSDK+-isysroot $OSXSDK} -I${X11INC}"

# some extra flags based on CPU features
export CPUFLAGS="-mmmx -msse -msse2 -msse3 -mfpmath=sse"
# set our CFLAGS to something useful, and specify we should be using 32-bit
export CFLAGS="-g -O2 -arch i386 -m32 ${CPUFLAGS} ${OSXSDK+-isysroot $OSXSDK} ${OSXVERSIONMIN+-mmacosx-version-min=$OSXVERSIONMIN} ${CPPFLAGS}"
export CXXFLAGS=${CFLAGS}
echo "CFLAGS and CXXFLAGS set to: ${CFLAGS}"

# linker flags
#   always prefer our Wine install path's lib dir
#   set the sysroot if need be
export LDFLAGS="-L${WINELIBPATH} ${OSXSDK+-isysroot $OSXSDK} -L${X11LIB} -framework CoreServices -lz -L${X11LIB} -lGL -lGLU"
echo "LDFLAGS set to: ${LDFLAGS}"

# pkg-config config
#   system and stuff we build only
export PKG_CONFIG_PATH="${WINELIBPATH}/pkgconfig:/usr/lib/pkgconfig:${X11LIB}/pkgconfig"

# aclocal/automake
#   include custom, X11, other system stuff
export ACLOCAL="aclocal -I ${WINEINSTALLPATH}/share/aclocal -I ${X11DIR}/share/aclocal -I /usr/share/aclocal"

# make
#   how many jobs do we run concurrently?
#   core count + 1
export MAKE="make"
export MAKEJOBS=$((`sysctl -n machdep.cpu.core_count | tr -d " "`+1))
export CONCURRENTMAKE="${MAKE} -j${MAKEJOBS}"

# configure
#   use a common prefix
#   disable static libs by default
export CONFIGURE="./configure"
export CONFIGURECOMMONPREFIX="--prefix=${WINEINSTALLPATH}"
export CONFIGURECOMMONLIBOPTS="--enable-shared=yes --enable-static=no"

# SHA-1 sum program
#   openssl is available everywhere
export SHA1SUM="openssl dgst -sha1"

# downloader program
#   curl's avail everywhere!
export CURL="curl"
export CURLOPTS="-kL"
echo "base downloader command: ${CURL} ${CURLOPTS}"

# extract commands
#   currently we only have gzip/bzip2 tar files
export TARGZ="tar -zxvf"
export TARBZ2="tar -jxvf"
export TARXZ="tarxz"
export XZ="xz"

# git needs these?
#   not using Git yet, but we will in the future
#   apparently these have to be set or Git will try to use Fink/MacPorts
#   so much smarter than us, Git
export NO_FINK=1
export NO_DARWIN_PORTS=1

# path
#   pull out fink, macports, gentoo - what about homebrew?
#   set our Wine install dir's bin and X11 bin before everything else
export PATH=$(echo $PATH | tr ":" "\n" | egrep -v ^"(/opt/local|/sw|/opt/gentoo)" | xargs echo  | tr " " ":")
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
	${CC} ${CFLAGS} ${WINEBUILDPATH}/$$_compiler_check.c -o ${WINEBUILDPATH}/$$_compiler_check || fail_and_exit "compiler cannot output executables"
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
		echo "successfully verified ${FILE}"
	fi
}

#
# clean_source_dir
#   cleans up a source directory - receives base dir + source dir
#
function clean_source_dir {
	SOURCEDIR=${1}
	BASEDIR=${2}
	if [ ${NOCLEANSOURCE} -eq 1 ] ; then
		echo "--no-clean-source set, not cleaning ${BASEDIR}/${SOURCEDIR}"
		return
	fi
	if [ -d ${BASEDIR}/${SOURCEDIR} ] ; then
		pushd . >/dev/null 2>&1
		echo "cleaning up ${BASEDIR}/${SOURCEDIR} for fresh compile"
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
	SOURCEDIR=${4}
	if [ ${NOCLEANSOURCE} -eq 1 ] ; then
		if [ -d ${EXTRACTDIR}/${SOURCEDIR} ] ; then
			echo "--no-clean-source set, not extracting ${EXTRACTFILE}"
			return
		fi
	fi
	echo "extracting ${EXTRACTFILE} to ${EXTRACTDIR} with '${EXTRACTCMD}'"
	if [ ! -d ${EXTRACTDIR} ] ; then
		mkdir -p ${EXTRACTDIR} || fail_and_exit "could not create ${EXTRACTDIR}"
	fi
	pushd . >/dev/null 2>&1
	cd ${EXTRACTDIR} || fail_and_exit "could not cd into ${EXTRACTDIR}"
	if [ "${EXTRACTCMD}" == "tarxz" ] ; then
		xzcat ${EXTRACTFILE} | tar -xvf - || fail_and_exit "could not extract ${EXTRACTFILE}"
	else
		${EXTRACTCMD} ${EXTRACTFILE} || fail_and_exit "could not extract ${EXTRACTFILE}"
	fi
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
	CONFIGUREDFILE="${SOURCEDIR}/.$(basename ${0})-configured"
	if [ ! -d ${SOURCEDIR} ] ; then
		fail_and_exit "could not find ${SOURCEDIR}"
	fi
	if [ ${NORECONFIGURE} -eq 1 ] ; then
		if [ -f ${CONFIGUREDFILE} ] ; then
			echo "--no-reconfigure set, not reconfiguring in ${SOURCEDIR}"
			return
		fi
	fi
	echo "running '${CONFIGURECMD}' in ${SOURCEDIR}"
	pushd . >/dev/null 2>&1
	cd ${SOURCEDIR} || fail_and_exit "source directory ${SOURCEDIR} does not seem to exist"
	${CONFIGURECMD} || fail_and_exit "could not run configure command '${CONFIGURECMD}' in ${SOURCEDIR}"
	touch ${CONFIGUREDFILE} || fail_and_exit "could not touch ${CONFIGUREDFILE}"
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
	BUILTFILE="${BUILDDIR}/.$(basename ${0})-built"
	if [ ! -d ${BUILDDIR} ] ; then
		fail_and_exit "${BUILDDIR} does not exist"
	fi
	if [ ${NOREBUILD} -eq 1 ] ; then
		if [ -f ${BUILTFILE} ] ; then
			echo "--no-rebuild set, not rebuilding in ${BUILDDIR}"
			return
		fi
	fi
	pushd . >/dev/null 2>&1
	cd ${BUILDDIR} || fail_and_exit "build directory ${BUILDDIR} does not seem to exist"
	${BUILDCMD} || fail_and_exit "could not run '${BUILDCMD}' in ${BUILDDIR}"
	touch ${BUILTFILE} || fail_and_exit "could not touch ${BUILTFILE}"
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
# xz
#
XZVER="5.0.3"
XZFILE="xz-${XZVER}.tar.bz2"
XZURL="http://tukaani.org/xz/${XZFILE}"
XZSHA1SUM="79661fd1c24603437e325d76732046b1da683b32"
XZDIR="xz-${XZVER}"
function clean_xz {
	clean_source_dir "${XZDIR}" "${WINEBUILDPATH}"
}
function get_xz {
	get_file "${XZFILE}" "${WINESOURCEPATH}" "${XZURL}"
}
function check_xz {
	check_sha1sum "${WINESOURCEPATH}/${XZFILE}" "${XZSHA1SUM}"
}
function extract_xz {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${XZFILE}" "${WINEBUILDPATH}" "${XZDIR}"
}
function configure_xz {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --enable-small --disable-assembler" "${WINEBUILDPATH}/${XZDIR}"
}
function build_xz {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${XZDIR}"
}
function install_xz {
	clean_xz
	extract_xz
	configure_xz
	build_xz
	install_package "${MAKE} install" "${WINEBUILDPATH}/${XZDIR}"
}

#
# libffi
#
LIBFFIVER="3.0.11"
LIBFFIFILE="libffi-${LIBFFIVER}.tar.gz"
LIBFFIURL="ftp://sourceware.org/pub/libffi/${LIBFFIFILE}"
LIBFFISHA1SUM="bff6a6c886f90ad5e30dee0b46676e8e0297d81d"
LIBFFIDIR="libffi-${LIBFFIVER}"
function clean_libffi {
	clean_source_dir "${LIBFFIDIR}" "${WINEBUILDPATH}"
}
function get_libffi {
	get_file "${LIBFFIFILE}" "${WINESOURCEPATH}" "${LIBFFIURL}"
}
function check_libffi {
	check_sha1sum "${WINESOURCEPATH}/${LIBFFIFILE}" "${LIBFFISHA1SUM}"
}
function extract_libffi {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBFFIFILE}" "${WINEBUILDPATH}" "${LIBFFIDIR}"
}
function configure_libffi {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBFFIDIR}"
}
function build_libffi {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBFFIDIR}"
}
function install_libffi {
	clean_libffi
	extract_libffi
	configure_libffi
	build_libffi
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBFFIDIR}"
}

#
# pkg-config
#
PKGCONFIGVER="0.25"
PKGCONFIGFILE="pkg-config-${PKGCONFIGVER}.tar.gz"
PKGCONFIGURL="http://pkgconfig.freedesktop.org/releases/${PKGCONFIGFILE}"
PKGCONFIGSHA1SUM="8922aeb4edeff7ed554cc1969cbb4ad5a4e6b26e"
PKGCONFIGDIR="pkg-config-${PKGCONFIGVER}"
function clean_pkgconfig {
	clean_source_dir "${PKGCONFIGDIR}" "${WINEBUILDPATH}"
}
function get_pkgconfig {
	get_file "${PKGCONFIGFILE}" "${WINESOURCEPATH}" "${PKGCONFIGURL}"
}
function check_pkgconfig {
	check_sha1sum "${WINESOURCEPATH}/${PKGCONFIGFILE}" "${PKGCONFIGSHA1SUM}"
}
function extract_pkgconfig {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${PKGCONFIGFILE}" "${WINEBUILDPATH}" "${PKGCONFIGDIR}"
}
function configure_pkgconfig {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}
function build_pkgconfig {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}
function install_pkgconfig {
	clean_pkgconfig
	extract_pkgconfig
	configure_pkgconfig
	build_pkgconfig
	install_package "${MAKE} install" "${WINEBUILDPATH}/${PKGCONFIGDIR}"
}

#
# pkgconfig026
#
PKGCONFIG026VER="0.26"
PKGCONFIG026FILE="pkg-config-${PKGCONFIG026VER}.tar.gz"
PKGCONFIG026URL="http://pkgconfig.freedesktop.org/releases/${PKGCONFIG026FILE}"
PKGCONFIG026SHA1SUM="fd71a70b023b9087c8a7bb76a0dc135a61059652"
PKGCONFIG026DIR="pkg-config-${PKGCONFIG026VER}"
function clean_pkgconfig026 {
	clean_source_dir "${PKGCONFIG026DIR}" "${WINEBUILDPATH}"
}
function get_pkgconfig026 {
	get_file "${PKGCONFIG026FILE}" "${WINESOURCEPATH}" "${PKGCONFIG026URL}"
}
function check_pkgconfig026 {
	check_sha1sum "${WINESOURCEPATH}/${PKGCONFIG026FILE}" "${PKGCONFIG026SHA1SUM}"
}
function extract_pkgconfig026 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${PKGCONFIG026FILE}" "${WINEBUILDPATH}" "${PKGCONFIG026DIR}"
}
function configure_pkgconfig026 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${PKGCONFIG026DIR}"
}
function build_pkgconfig026 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${PKGCONFIG026DIR}"
}
function install_pkgconfig026 {
	clean_pkgconfig026
	extract_pkgconfig026
	configure_pkgconfig026
	build_pkgconfig026
	install_package "${MAKE} install" "${WINEBUILDPATH}/${PKGCONFIG026DIR}"
}

#
# gettext
#
GETTEXTVER="0.18.1.1"
GETTEXTFILE="gettext-${GETTEXTVER}.tar.gz"
GETTEXTURL="http://ftp.gnu.org/pub/gnu/gettext/${GETTEXTFILE}"
GETTEXTSHA1SUM="5009deb02f67fc3c59c8ce6b82408d1d35d4e38f"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GETTEXTFILE}" "${WINEBUILDPATH}" "${GETTEXTDIR}"
}
function configure_gettext {
	echo "attempting to fixup gettext"
	pushd . >/dev/null 2>&1
	cd "${WINEBUILDPATH}/${GETTEXTDIR}" || fail_and_exit "could not cd into gettext dir ${WINEBUILDPATH}/${GETTEXTDIR}"
	# turn off examples subdir manually
	sed -i.ORIG 's# gnulib-tests examples# gnulib-tests#g' gettext-tools/Makefile.in  || fail_and_exit "in place sed for gettext-tools/Makefile.in failed"
	# stpncpy broken/defined on Lion?
	if [ ${DARWINMAJ} -ge 11 ] ; then
		echo "attempting to fixup gettext for Darwin 11+"
		sed -i.ORIG 's#^extern char \*stpncpy#//extern char *stpncpy#g' gettext-tools/configure  || fail_and_exit "in place sed for gettext-tools/configure"
		echo "successfully changed gettext-tools/configure for Darwin 11+"
	fi
	echo "successfully changed gettext-tools/Makefile.in"
	popd
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-java --disable-native-java --without-emacs --without-git --without-cvs --disable-csharp --disable-native-java --with-included-gettext --with-included-glib --with-included-libcroco --with-included-libxml" "${WINEBUILDPATH}/${GETTEXTDIR}"
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
JPEGVER="8d"
JPEGFILE="jpegsrc.v${JPEGVER}.tar.gz"
JPEGURL="http://www.ijg.org/files/${JPEGFILE}"
JPEGSHA1SUM="f080b2fffc7581f7d19b968092ba9ebc234556ff"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${JPEGFILE}" "${WINEBUILDPATH}" "${JPEGDIR}"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${JBIGKITFILE}" "${WINEBUILDPATH}" "${JBIGKITDIR}"
}
function build_jbigkit {
	pushd . >/dev/null 2>&1
	echo "now building in ${WINEBUILDPATH}/${JBIGKITDIR}"
	cd ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig || fail_and_exit "could not cd to the JBIG source directory"
	BUILTFILE="${WINEBUILDPATH}/${JBIGKITDIR}/.$(basename ${0})-built"
	if [ ${NOREBUILD} -eq 1 ] ; then
		if [ -f ${BUILTFILE} ] ; then
			echo "--no-rebuild set, not rebuilding in ${WINEBUILDPATH}/${JBIGKITDIR}/libjbig"
			return
		fi
	fi
	JBIGKITOBJS=""
	for JBIGKITSRC in jbig jbig_ar ; do
		rm -f ${JBIGKITSRC}.o
		echo "${CC} ${CFLAGS} -O2 -Wall -I. -dynamic -ansi -pedantic -c ${JBIGKITSRC}.c -o ${JBIGKITSRC}.o"
		${CC} ${CFLAGS} -O2 -Wall -I. -dynamic -ansi -pedantic -c ${JBIGKITSRC}.c -o ${JBIGKITSRC}.o || fail_and_exit "failed building jbigkit's ${JBIGKITSRC}.c"
		JBIGKITOBJS+="${JBIGKITSRC}.o "
	done
	echo "creating libjbig shared library with libtool"
	libtool -dynamic -v -o libjbig.${JBIGKITVER}.dylib -install_name ${WINELIBPATH}/libjbig.${JBIGKITVER}.dylib -compatibility_version ${JBIGKITVER} -current_version ${JBIGKITVER} -lc ${JBIGKITOBJS} || fail_and_exit "failed to build jbigkit shared library"
	touch ${BUILTFILE} || fail_and_exit "could not touch ${BUILTFILE}"
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
	# XXX - remove manual cleanup? 'ln -Ffs' should manage this for us
	if [ ${NOCLEANPREFIX} -eq 1 ] ; then
		echo "--no-clean-prefix, manually removing libjbig symlinks"
		if [ -L ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib ] ; then
			unlink ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib || fail_and_exit "could not remove existing libjbig symbolic link"
		fi
		if [ -L ${WINELIBPATH}/libjbig.dylib ] ; then
			unlink ${WINELIBPATH}/libjbig.dylib || fail_and_exit "could not remove existing libjbig symbolic link"
		fi
	fi
	ln -Ffs libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib || fail_and_exit "could not create libjbig symlink"
	ln -Ffs libjbig.${JBIGKITVER}.dylib ${WINELIBPATH}/libjbig.dylib || fail_and_exit "could not create libjbig symlink"
	echo "installing libjbig header files"
	for JBIGKITHDR in jbig.h jbig_ar.h ; do
		install -m 644 ${JBIGKITHDR} ${WINEINCLUDEPATH}/${JBIGKITHDR} || fail_and_exit "could not install JBIG header ${JBIGKITHDR}"
	done
	popd >/dev/null 2>&1
}

#
# tiff
#
TIFFVER="3.9.6"
TIFFFILE="tiff-${TIFFVER}.tar.gz"
TIFFURL="http://download.osgeo.org/libtiff/${TIFFFILE}"
TIFFSHA1SUM="f0e86d3fc3a52b29f4ca76b8436f5b5d6618b18b"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${TIFFFILE}" "${WINEBUILDPATH}" "${TIFFDIR}"
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
# libpng12
#
LIBPNG12VER="1.2.49"
LIBPNG12SHA1SUM="e60a69770a7dddca252578a2de5e79e24e3f94dd"
LIBPNG12FILE="libpng-${LIBPNG12VER}.tar.gz"
LIBPNG12URL="http://downloads.sourceforge.net/libpng/${LIBPNG12FILE}"
LIBPNG12DIR="libpng-${LIBPNG12VER}"
function clean_libpng12 {
	clean_source_dir "${LIBPNG12DIR}" "${WINEBUILDPATH}"
}
function get_libpng12 {
	get_file "${LIBPNG12FILE}" "${WINESOURCEPATH}" "${LIBPNG12URL}"
}
function check_libpng12 {
	check_sha1sum "${WINESOURCEPATH}/${LIBPNG12FILE}" "${LIBPNG12SHA1SUM}"
}
function extract_libpng12 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBPNG12FILE}" "${WINEBUILDPATH}" "${LIBPNG12DIR}"
}
function configure_libpng12 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBPNG12DIR}"
}
function build_libpng12 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBPNG12DIR}"
}
function install_libpng12 {
	clean_libpng12
	extract_libpng12
	configure_libpng12
	build_libpng12
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBPNG12DIR}"
}

#
# libpng14
#
LIBPNG14VER="1.4.4"
LIBPNG14SHA1SUM="245490b22086a6aff8964b7d32383a17814d8ebf"
LIBPNG14FILE="libpng-${LIBPNG14VER}.tar.gz"
LIBPNG14URL="http://downloads.sourceforge.net/libpng/${LIBPNG14FILE}"
LIBPNG14DIR="libpng-${LIBPNG14VER}"
function clean_libpng14 {
	clean_source_dir "${LIBPNG14DIR}" "${WINEBUILDPATH}"
}
function get_libpng14 {
	get_file "${LIBPNG14FILE}" "${WINESOURCEPATH}" "${LIBPNG14URL}"
}
function check_libpng14 {
	check_sha1sum "${WINESOURCEPATH}/${LIBPNG14FILE}" "${LIBPNG14SHA1SUM}"
}
function extract_libpng14 {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBPNG14FILE}" "${WINEBUILDPATH}" "${LIBPNG14DIR}"
}
function configure_libpng14 {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBPNG14DIR}"
}
function build_libpng14 {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBPNG14DIR}"
}
function install_libpng14 {
	clean_libpng14
	extract_libpng14
	configure_libpng14
	build_libpng14
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBPNG14DIR}"
}

#
# libxml
#
LIBXML2VER="2.8.0"
LIBXML2FILE="libxml2-${LIBXML2VER}.tar.gz"
LIBXML2URL="ftp://xmlsoft.org/libxml2/${LIBXML2FILE}"
LIBXML2SHA1SUM="a0c553bd51ba79ab6fff26dc700004c6a41f5250"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBXML2FILE}" "${WINEBUILDPATH}" "${LIBXML2DIR}"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBXSLTFILE}" "${WINEBUILDPATH}" "${LIBXSLTDIR}"
}
function configure_libxslt {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-libxml-prefix=${WINEINSTALLPATH} --without-python" "${WINEBUILDPATH}/${LIBXSLTDIR}"
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
# glib
#
GLIBBASEVER="2.32"
GLIBVER="${GLIBBASEVER}.3"
GLIBFILE="glib-${GLIBVER}.tar.xz"
GLIBURL="http://ftp.gnome.org/pub/gnome/sources/glib/${GLIBBASEVER}/${GLIBFILE}"
GLIBSHA1SUM="429355327aaf69d2c21cbefcb20c61db94e0acec"
GLIBDIR="glib-${GLIBVER}"
function clean_glib {
	clean_source_dir "${GLIBDIR}" "${WINEBUILDPATH}"
}
function get_glib {
	get_file "${GLIBFILE}" "${WINESOURCEPATH}" "${GLIBURL}"
}
function check_glib {
	check_sha1sum "${WINESOURCEPATH}/${GLIBFILE}" "${GLIBSHA1SUM}"
}
function extract_glib {
	extract_file "${TARXZ}" "${WINESOURCEPATH}/${GLIBFILE}" "${WINEBUILDPATH}" "${GLIBDIR}"
}
function configure_glib {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${GLIBDIR}"
}
function build_glib {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GLIBDIR}"
}
function install_glib {
	clean_glib
	extract_glib
	configure_glib
	build_glib
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GLIBDIR}"
}


#
# mpg123
#
MPG123VER="1.14.2"
MPG123FILE="mpg123-${MPG123VER}.tar.bz2"
MPG123URL="http://downloads.sourceforge.net/mpg123/${MPG123FILE}"
MPG123SHA1SUM="887a453e49e3d49d539a712ee66a8d9da16e3325"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${MPG123FILE}" "${WINEBUILDPATH}" "${MPG123DIR}"
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
GSMVER="1.0"
GSMMAJOR=$(echo ${GSMVER} | awk -F\. '{print $1}')
GSMPL="13"
GSMFILE="gsm-${GSMVER}.${GSMPL}.tar.gz"
GSMURL="http://osxwinebuilder.googlecode.com/files/${GSMFILE}"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GSMFILE}" "${WINEBUILDPATH}" "${GSMDIR}"
}
function build_gsm {
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${GSMDIR} || fail_and_exit "could not cd to the GSM source directory"
	BUILTFILE="${WINEBUILDPATH}/${GSMDIR}/.$(basename ${0})-built"
	if [ ${NOREBUILD} -eq 1 ] ; then
		if [ -f ${BUILTFILE} ] ; then
			echo "--no-rebuild set, not rebuilding in ${WINEBUILDPATH}/${GSMDIR}"
			return
		fi
	fi
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
	touch ${BUILTFILE} || fail_and_exit "could not touch ${BUILTFILE}"
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
	# XXX - remove manual cleanup? 'ln -Ffs' should manage this for us
	if [ ${NOCLEANPREFIX} -eq 1 ] ; then
		echo "--no-clean-prefix, manually removing libgsm symlinks"
		if [ -L ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib ] ; then
			unlink ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib || fail_and_exit "could not remove existing libgsm symbolic link"
		fi
		if [ -L ${WINELIBPATH}/libgsm.dylib ] ; then
			unlink ${WINELIBPATH}/libgsm.dylib || fail_and_exit "could not remove existing libgsm symbolic link"
		fi
	fi
	ln -Ffs libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib || fail_and_exit "could not create a libgsm symbolic link"
	ln -Ffs libgsm.${GSMVER}.${GSMPL}.dylib ${WINELIBPATH}/libgsm.dylib || fail_and_exit "could not create a libgsm symbolic link"
	echo "installing libgsm header file"
	install -m 644 inc/gsm.h ${WINEINCLUDEPATH}/gsm.h || fail_and_exit "could not install the GSM gsm.h header file"
	popd >/dev/null 2>&1
}

#
# freetype
#
FREETYPEVER="2.4.9"
FREETYPEFILE="freetype-${FREETYPEVER}.tar.bz2"
FREETYPEURL="http://downloads.sourceforge.net/freetype/freetype2/${FREETYPEFILE}"
FREETYPESHA1SUM="5cb80ab9d369c4e81a2221bcf45adcea2c996b9b"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${FREETYPEFILE}" "${WINEBUILDPATH}" "${FREETYPEDIR}"
}
function configure_freetype {
	# set subpixel rendering flag
	export FT_CONFIG_OPTION_SUBPIXEL_RENDERING=1
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${FREETYPEDIR}"
	echo "attempting to enable FreeType's subpixel rendering and bytecode interpretter in ${WINEBUILDPATH}/${FREETYPEDIR}"
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${FREETYPEDIR} || fail_and_exit "could not cd to ${FREETYPEDIR} for patching"
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
FONTCONFIGVER="2.9.0"
FONTCONFIGFILE="fontconfig-${FONTCONFIGVER}.tar.gz"
FONTCONFIGURL="http://www.freedesktop.org/software/fontconfig/release/${FONTCONFIGFILE}"
FONTCONFIGSHA1SUM="1ab2f437c2261028ae7969892277af2d8d8db489"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${WINEBUILDPATH}" "${FONTCONFIGDIR}"
	#extract_file "${TARBZ2}" "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${WINEBUILDPATH}" "${FONTCONFIGDIR}"
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
LCMSURL="http://downloads.sourceforge.net/lcms/${LCMSFILE}"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LCMSFILE}" "${WINEBUILDPATH}" "${LCMSDIR}"
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
LZOVER="2.06"
LZOFILE="lzo-${LZOVER}.tar.gz"
LZOURL="http://www.oberhumer.com/opensource/lzo/download/${LZOFILE}"
LZOSHA1SUM="a11768b8a168ec607750842bbef406f11547b904"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LZOFILE}" "${WINEBUILDPATH}" "${LZODIR}"
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
LIBGPGERRORVER="1.10"
LIBGPGERRORFILE="libgpg-error-${LIBGPGERRORVER}.tar.bz2"
LIBGPGERRORURL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${LIBGPGERRORFILE}"
LIBGPGERRORSHA1SUM="95b324359627fbcb762487ab6091afbe59823b29"
LIBGPGERRORDIR="libgpg-error-${LIBGPGERRORVER}"
function clean_libgpgerror {
	clean_source_dir "${LIBGPGERRORDIR}" "${WINEBUILDPATH}"
}
function get_libgpgerror {
	get_file "${LIBGPGERRORFILE}" "${WINESOURCEPATH}" "${LIBGPGERRORURL}"
}
function check_libgpgerror {
	check_sha1sum "${WINESOURCEPATH}/${LIBGPGERRORFILE}" "${LIBGPGERRORSHA1SUM}"
}
function extract_libgpgerror {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGPGERRORFILE}" "${WINEBUILDPATH}" "${LIBGPGERRORDIR}"
}
function configure_libgpgerror {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}
function build_libgpgerror {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}
function install_libgpgerror {
	clean_libgpgerror
	extract_libgpgerror
	configure_libgpgerror
	build_libgpgerror
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBGPGERRORDIR}"
}

#
# libgcrypt
#
LIBGCRYPTVER="1.5.0"
LIBGCRYPTFILE="libgcrypt-${LIBGCRYPTVER}.tar.bz2"
LIBGCRYPTURL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/${LIBGCRYPTFILE}"
LIBGCRYPTSHA1SUM="3e776d44375dc1a710560b98ae8437d5da6e32cf"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGCRYPTFILE}" "${WINEBUILDPATH}" "${LIBGCRYPTDIR}"
}
function configure_libgcrypt {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-gpg-error-prefix=${WINEINSTALLPATH} --disable-asm --disable-padlock-support --disable-aesni-support" "${WINEBUILDPATH}/${LIBGCRYPTDIR}"
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
# gmp
#
GMPVER="5.0.5"
GMPFILE="gmp-${GMPVER}.tar.bz2"
GMPURL="ftp://ftp.gmplib.org/pub/gmp-${GMPVER}/${GMPFILE}"
GMPSHA1SUM="12a662456033e21aed3e318aef4177f4000afe3b"
GMPDIR="gmp-${GMPVER}"
function clean_gmp {
	clean_source_dir "${GMPDIR}" "${WINEBUILDPATH}"
}
function get_gmp {
	get_file "${GMPFILE}" "${WINESOURCEPATH}" "${GMPURL}"
}
function check_gmp {
	check_sha1sum "${WINESOURCEPATH}/${GMPFILE}" "${GMPSHA1SUM}"
}
function extract_gmp {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GMPFILE}" "${WINEBUILDPATH}" "${GMPDIR}"
}
function configure_gmp {
	export ABI=32
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${GMPDIR}"
	unset ABI
}
function build_gmp {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GMPDIR}"
}
function install_gmp {
	clean_gmp
	extract_gmp
	configure_gmp
	build_gmp
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GMPDIR}"
}

#
# nettle
#
NETTLEVER="2.4"
NETTLEFILE="nettle-${NETTLEVER}.tar.gz"
NETTLEURL="ftp://ftp.lysator.liu.se/pub/security/lsh/${NETTLEFILE}"
NETTLESHA1SUM="1df0cd013e83f73b78a5521411a67e331de3dfa6"
NETTLEDIR="nettle-${NETTLEVER}"
function clean_nettle {
	clean_source_dir "${NETTLEDIR}" "${WINEBUILDPATH}"
}
function get_nettle {
	get_file "${NETTLEFILE}" "${WINESOURCEPATH}" "${NETTLEURL}"
}
function check_nettle {
	check_sha1sum "${WINESOURCEPATH}/${NETTLEFILE}" "${NETTLESHA1SUM}"
}
function extract_nettle {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${NETTLEFILE}" "${WINEBUILDPATH}" "${NETTLEDIR}"
}
function configure_nettle {
	echo "attempting to fix nettle libraries for configure"
	pushd . >/dev/null 2>&1 
	cd ${WINEBUILDPATH}/${NETTLEDIR} || fail_and_exit "could not cd into ${WINEBUILDPATH}/${NETTLEDIR}"
	sed -i.NETTLELIBS "s#LIBNETTLE_LIBS=''#LIBNETTLE_LIBS='\$(LDFLAGS) \$(LIBS)'#g" configure
	sed -i.HOGWEEDLIBS "s#LIBHOGWEED_LIBS=''#LIBHOGWEED_LIBS='\$(LDFLAGS) \$(LIBS) -L. -lnettle -lgmp'#g" configure
	echo "nettle libraries fixed successfully"
	export OLDCC=${CC}
	export CC="${CC} -m32 -arch i386"
	export ABI=32
	export LIBS="-lgmp"
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-assembler" "${WINEBUILDPATH}/${NETTLEDIR}"
	unset LIBS
	unset ABI
	export CC=${OLDCC}
	sed -i.TESTSUITE 's#testsuite##g' Makefile
	popd
}
function build_nettle {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${NETTLEDIR}"
}
function install_nettle {
	clean_nettle
	extract_nettle
	configure_nettle
	build_nettle
	install_package "${MAKE} install" "${WINEBUILDPATH}/${NETTLEDIR}"
}

#
# p11-kit
#
P11KITVER="0.12"
P11KITFILE="p11-kit-${P11KITVER}.tar.gz"
P11KITURL="http://p11-glue.freedesktop.org/releases/${P11KITFILE}"
P11KITSHA1SUM="25671198425b8055024067b3cc469a8d955581b0"
P11KITDIR="p11-kit-${P11KITVER}"
function clean_p11kit {
	clean_source_dir "${P11KITDIR}" "${WINEBUILDPATH}"
}
function get_p11kit {
	get_file "${P11KITFILE}" "${WINESOURCEPATH}" "${P11KITURL}"
}
function check_p11kit {
	check_sha1sum "${WINESOURCEPATH}/${P11KITFILE}" "${P11KITSHA1SUM}"
}
function extract_p11kit {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${P11KITFILE}" "${WINEBUILDPATH}" "${P11KITDIR}"
}
function configure_p11kit {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${P11KITDIR}"
}
function build_p11kit {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${P11KITDIR}"
}
function install_p11kit {
	clean_p11kit
	extract_p11kit
	configure_p11kit
	build_p11kit
	install_package "${MAKE} install" "${WINEBUILDPATH}/${P11KITDIR}"
}

#
# gnutls
#
GNUTLSVER="2.12.9"
GNUTLSFILE="gnutls-${GNUTLSVER}.tar.bz2"
GNUTLSURL="ftp://ftp.gnu.org/pub/gnu/gnutls/${GNUTLSFILE}"
GNUTLSSHA1SUM="9a775466d5bf6976e77e5f659d136e0a4733a58a"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GNUTLSFILE}" "${WINEBUILDPATH}" "${GNUTLSDIR}"
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
UNIXODBCVER="2.3.0"
UNIXODBCFILE="unixODBC-${UNIXODBCVER}.tar.gz"
UNIXODBCURL="http://www.unixodbc.org/${UNIXODBCFILE}"
UNIXODBCSHA1SUM="b2839b5210906e3ee286a4b621f177db9c7be7a8"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${UNIXODBCFILE}" "${WINEBUILDPATH}" "${UNIXODBCDIR}"
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
LIBEXIFVER="0.6.20"
LIBEXIFFILE="libexif-${LIBEXIFVER}.tar.bz2"
LIBEXIFURL="http://downloads.sourceforge.net/libexif/${LIBEXIFFILE}"
LIBEXIFSHA1SUM="d7cce9098169269695852db20d24350c2d3c10fe"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBEXIFFILE}" "${WINEBUILDPATH}" "${LIBEXIFDIR}"
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
LIBUSBVER="1.0.9"
LIBUSBFILE="libusb-${LIBUSBVER}.tar.bz2"
LIBUSBURL="http://downloads.sourceforge.net/libusb/${LIBUSBFILE}"
LIBUSBSHA1SUM="025582ff2f6216e2dbc2610ae16b2e073e1b3346"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBUSBFILE}" "${WINEBUILDPATH}" "${LIBUSBDIR}"
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
# libusb-compat
#
LIBUSBCOMPATVER="0.1.4"
LIBUSBCOMPATFILE="libusb-compat-${LIBUSBCOMPATVER}.tar.bz2"
LIBUSBCOMPATURL="http://downloads.sourceforge.net/libusb/${LIBUSBCOMPATFILE}"
LIBUSBCOMPATSHA1SUM="fdc1df6f5cf7b71de7a74292aeea1aa2a39552ae"
LIBUSBCOMPATDIR="libusb-compat-${LIBUSBCOMPATVER}"
function clean_libusbcompat {
	clean_source_dir "${LIBUSBCOMPATDIR}" "${WINEBUILDPATH}"
}
function get_libusbcompat {
	get_file "${LIBUSBCOMPATFILE}" "${WINESOURCEPATH}" "${LIBUSBCOMPATURL}"
}
function check_libusbcompat {
	check_sha1sum "${WINESOURCEPATH}/${LIBUSBCOMPATFILE}" "${LIBUSBCOMPATSHA1SUM}"
}
function extract_libusbcompat {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBUSBCOMPATFILE}" "${WINEBUILDPATH}" "${LIBUSBCOMPATDIR}"
}
function configure_libusbcompat {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBUSBCOMPATDIR}"
}
function build_libusbcompat {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBUSBCOMPATDIR}"
}
function install_libusbcompat {
	clean_libusbcompat
	extract_libusbcompat
	configure_libusbcompat
	build_libusbcompat
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBUSBCOMPATDIR}"
}

#
# gd
#
GDVER="2.0.36RC1"
GDFILE="gd-${GDVER}.tar.bz2"
# XXX - http://code.google.com/p/osxwinebuilder/issues/detail?id=14
# XXX - http://www.boutell.com/gd/
#GDURL="http://www.libgd.org/releases/${GDFILE}"
GDURL="http://osxwinebuilder.googlecode.com/files/${GDFILE}"
GDSHA1SUM="415300e288348ed0d806fa2f3b7815604d8b5eec"
GDDIR="gd-${GDVER}"
function clean_gd {
	clean_source_dir "${GDDIR}" "${WINEBUILDPATH}"
}
function get_gd {
	get_file "${GDFILE}" "${WINESOURCEPATH}" "${GDURL}"
}
function check_gd {
	check_sha1sum "${WINESOURCEPATH}/${GDFILE}" "${GDSHA1SUM}"
}
function extract_gd {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GDFILE}" "${WINEBUILDPATH}" "${GDDIR}"
}
function configure_gd {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} --with-png=${WINEINSTALLPATH} --with-freetype=${WINEINSTALLPATH} --with-fontconfig=${WINEINSTALLPATH} --with-jpeg=${WINEINSTALLPATH}" "${WINEBUILDPATH}/${GDDIR}"
}
function build_gd {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GDDIR}"
}
function install_gd {
	clean_gd
	extract_gd
	configure_gd
	build_gd
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GDDIR}"
}

#
# libgphoto2
#
LIBGPHOTO2VER="2.4.14"
LIBGPHOTO2FILE="libgphoto2-${LIBGPHOTO2VER}.tar.bz2"
LIBGPHOTO2URL="http://downloads.sourceforge.net/gphoto/libgphoto/${LIBGPHOTO2FILE}"
LIBGPHOTO2SHA1SUM="c932f44d51e820245ff3394ee01a5e9df429dfef"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBGPHOTO2FILE}" "${WINEBUILDPATH}" "${LIBGPHOTO2DIR}"
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
SANEBACKENDSVER="1.0.22"
SANEBACKENDSFILE="sane-backends-${SANEBACKENDSVER}.tar.gz"
# XXX - http://code.google.com/p/osxwinebuilder/issues/detail?id=15
#SANEBACKENDSURL="ftp://ftp.sane-project.org/pub/sane/sane-backends-${SANEBACKENDSVER}/${SANEBACKENDSFILE}"
SANEBACKENDSURL="https://alioth.debian.org/frs/download.php/3503/${SANEBACKENDSFILE}"
SANEBACKENDSSHA1SUM="dc04d6e6fd18791d8002c3fdb23e89fef3327135"
SANEBACKENDSDIR="sane-backends-${SANEBACKENDSVER}"
function clean_sanebackends {
	clean_source_dir "${SANEBACKENDSDIR}" "${WINEBUILDPATH}"
}
function get_sanebackends {
	get_file "${SANEBACKENDSFILE}" "${WINESOURCEPATH}" "${SANEBACKENDSURL}"
}
function check_sanebackends {
	check_sha1sum "${WINESOURCEPATH}/${SANEBACKENDSFILE}" "${SANEBACKENDSSHA1SUM}"
}
function extract_sanebackends {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${SANEBACKENDSFILE}" "${WINEBUILDPATH}" "${SANEBACKENDSDIR}"
}
function configure_sanebackends {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-gphoto2 --enable-libusb_1_0" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
	if [ ${DARWINMAJ} -ge 11 ] ; then
		echo "attempting to run fixup on SANE backends include"
		pushd . >/dev/null 2>&1
		cd ${WINEBUILDPATH}/${SANEBACKENDSDIR} || fail_and_exit "could not cd into ${WINEBUILDPATH}/${SANEBACKENDSDIR}"
		cp include/sane/sane.h{,.ORIG} || fail_and_exit "could not backup include/sane/sane.h"
		( ( echo '#include <sys/types.h>' ; cat include/sane/sane.h.ORIG ) > include/sane/sane.h ) || fail_and_exit "could not rewrite include/sane/sane.h"
		popd
		echo "successfully fixed SANE backends include"
	fi
}
function build_sanebackends {
	# 'make -j#' fails for #>1 on OS X <10.6/sane-backends 1.0.21.
	if [ ${DARWINMAJ} -lt 10 ] ; then
		build_package "${MAKE}" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
	else
		build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
	fi
}
function install_sanebackends {
	clean_sanebackends
	extract_sanebackends
	configure_sanebackends
	build_sanebackends
	install_package "${MAKE} install" "${WINEBUILDPATH}/${SANEBACKENDSDIR}"
}

#
# jasper
#
JASPERVER="1.900.1"
JASPERFILE="jasper-${JASPERVER}.zip"
JASPERURL="http://www.ece.uvic.ca/~mdadams/jasper/software/${JASPERFILE}"
JASPERSHA1SUM="9c5735f773922e580bf98c7c7dfda9bbed4c5191"
JASPERDIR="jasper-${JASPERVER}"
function clean_jasper {
	clean_source_dir "${JASPERDIR}" "${WINEBUILDPATH}"
}
function get_jasper {
	get_file "${JASPERFILE}" "${WINESOURCEPATH}" "${JASPERURL}"
}
function check_jasper {
	check_sha1sum "${WINESOURCEPATH}/${JASPERFILE}" "${JASPERSHA1SUM}"
}
function extract_jasper {
	extract_file "unzip" "${WINESOURCEPATH}/${JASPERFILE}" "${WINEBUILDPATH}" "${JASPERDIR}"
}
function configure_jasper {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${JASPERDIR}"
}
function build_jasper {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${JASPERDIR}"
}
function install_jasper {
	clean_jasper
	extract_jasper
	configure_jasper
	build_jasper
	install_package "${MAKE} install" "${WINEBUILDPATH}/${JASPERDIR}"
}

#
# libicns
#
LIBICNSVER="0.8.0"
LIBICNSFILE="libicns-${LIBICNSVER}.tar.gz"
LIBICNSURL="http://downloads.sourceforge.net/icns/${LIBICNSFILE}"
LIBICNSSHA1SUM="f74701266ad68df57a2fdc16780e7d75d8ec73b1"
LIBICNSDIR="libicns-${LIBICNSVER}"
function clean_libicns {
	clean_source_dir "${LIBICNSDIR}" "${WINEBUILDPATH}"
}
function get_libicns {
	get_file "${LIBICNSFILE}" "${WINESOURCEPATH}" "${LIBICNSURL}"
}
function check_libicns {
	check_sha1sum "${WINESOURCEPATH}/${LIBICNSFILE}" "${LIBICNSSHA1SUM}"
}
function extract_libicns {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBICNSFILE}" "${WINEBUILDPATH}" "${LIBICNSDIR}"
}
function configure_libicns {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBICNSDIR}"
}
function build_libicns {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBICNSDIR}"
}
function install_libicns {
	clean_libicns
	extract_libicns
	configure_libicns
	build_libicns
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBICNSDIR}"
}

#
# sdl
#
SDLVER="1.2.15"
SDLFILE="SDL-${SDLVER}.tar.gz"
SDLURL="http://www.libsdl.org/release/${SDLFILE}"
SDLSHA1SUM="0c5f193ced810b0d7ce3ab06d808cbb5eef03a2c"
SDLDIR="SDL-${SDLVER}"
function clean_sdl {
	clean_source_dir "${SDLDIR}" "${WINEBUILDPATH}"
}
function get_sdl {
	get_file "${SDLFILE}" "${WINESOURCEPATH}" "${SDLURL}"
}
function check_sdl {
	check_sha1sum "${WINESOURCEPATH}/${SDLFILE}" "${SDLSHA1SUM}"
}
function extract_sdl {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${SDLFILE}" "${WINEBUILDPATH}" "${SDLDIR}"
}
function configure_sdl {
	pushd . >/dev/null 2>&1
	cd ${WINEBUILDPATH}/${SDLDIR} || fail_and_exit "could not cd to ${WINEBUILDPATH}/${SDLDIR} to patch"
	sed -i.usr_X11_replacement s#/usr/X11/#${X11DIR}#g configure || fail_and_exit "could not replace /usr/X11/ with ${X11DIR} in ${WINEBUILDPATH}/${SDLDIR}/configure"
	sed -i.usr_X11R6_replacement s#/usr/X11R6/#${X11DIR}#g configure || fail_and_exit "could not replace /usr/X11R6/ with ${X11DIR} in ${WINEBUILDPATH}/${SDLDIR}/configure"
	popd >/dev/null 2>&1
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --x-includes=${X11INC} --x-libraries=${X11LIB}" "${WINEBUILDPATH}/${SDLDIR}"
}
function build_sdl {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${SDLDIR}"
}
function install_sdl {
	export PRECC=${CC}
	export PRECXX=${CXX}
	export CC="${CC} ${CFLAGS}"
	export CXX="${CXX} ${CXXFLAGS}"
	clean_sdl
	extract_sdl
	configure_sdl
	build_sdl
	install_package "${MAKE} install" "${WINEBUILDPATH}/${SDLDIR}"
	export CC="${PRECC}"
	export CXX="${PRECXX}"
}

#
# SDL_net
#
SDLNETVER="1.2.8"
SDLNETFILE="SDL_net-${SDLNETVER}.tar.gz"
SDLNETURL="http://www.libsdl.org/projects/SDL_net/release/${SDLNETFILE}"
SDLNETSHA1SUM="fd393059fef8d9925dc20662baa3b25e02b8405d"
SDLNETDIR="SDL_net-${SDLNETVER}"
function clean_sdlnet {
	clean_source_dir "${SDLNETDIR}" "${WINEBUILDPATH}"
}
function get_sdlnet {
	get_file "${SDLNETFILE}" "${WINESOURCEPATH}" "${SDLNETURL}"
}
function check_sdlnet {
	check_sha1sum "${WINESOURCEPATH}/${SDLNETFILE}" "${SDLNETSHA1SUM}"
}
function extract_sdlnet {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${SDLNETFILE}" "${WINEBUILDPATH}" "${SDLNETDIR}"
}
function configure_sdlnet {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${SDLNETDIR}"
}
function build_sdlnet {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${SDLNETDIR}"
}
function install_sdlnet {
	clean_sdlnet
	extract_sdlnet
	configure_sdlnet
	build_sdlnet
	install_package "${MAKE} install" "${WINEBUILDPATH}/${SDLNETDIR}"
}

#
# SDL_sound
#
SDLSOUNDVER="1.0.3"
SDLSOUNDFILE="SDL_sound-${SDLSOUNDVER}.tar.gz"
SDLSOUNDURL="http://icculus.org/SDL_sound/downloads/${SDLSOUNDFILE}"
SDLSOUNDSHA1SUM="1984bc20b2c756dc71107a5a0a8cebfe07e58cb1"
SDLSOUNDDIR="SDL_sound-${SDLSOUNDVER}"
function clean_sdlsound {
	clean_source_dir "${SDLSOUNDDIR}" "${WINEBUILDPATH}"
}
function get_sdlsound {
	get_file "${SDLSOUNDFILE}" "${WINESOURCEPATH}" "${SDLSOUNDURL}"
}
function check_sdlsound {
	check_sha1sum "${WINESOURCEPATH}/${SDLSOUNDFILE}" "${SDLSOUNDSHA1SUM}"
}
function extract_sdlsound {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${SDLSOUNDFILE}" "${WINEBUILDPATH}" "${SDLSOUNDDIR}"
}
function configure_sdlsound {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${SDLSOUNDDIR}"
}
function build_sdlsound {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${SDLSOUNDDIR}"
}
function install_sdlsound {
	clean_sdlsound
	extract_sdlsound
	configure_sdlsound
	build_sdlsound
	install_package "${MAKE} install" "${WINEBUILDPATH}/${SDLSOUNDDIR}"
}

#
# dosbox
#
DOSBOXVER="0.74"
DOSBOXFILE="dosbox-${DOSBOXVER}.tar.gz"
DOSBOXURL="http://downloads.sourceforge.net/dosbox/${DOSBOXFILE}"
DOSBOXSHA1SUM="2d99f0013350efb29b769ff19ddc8e4d86f4e77e"
DOSBOXDIR="dosbox-${DOSBOXVER}"
function clean_dosbox {
	clean_source_dir "${DOSBOXDIR}" "${WINEBUILDPATH}"
}
function get_dosbox {
	get_file "${DOSBOXFILE}" "${WINESOURCEPATH}" "${DOSBOXURL}"
}
function check_dosbox {
	check_sha1sum "${WINESOURCEPATH}/${DOSBOXFILE}" "${DOSBOXSHA1SUM}"
}
function extract_dosbox {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${DOSBOXFILE}" "${WINEBUILDPATH}" "${DOSBOXDIR}"
}
function configure_dosbox {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-sdl-prefix=${WINEINSTALLPATH}" "${WINEBUILDPATH}/${DOSBOXDIR}"
}
function build_dosbox {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${DOSBOXDIR}"
}
function install_dosbox {
	clean_dosbox
	extract_dosbox
	configure_dosbox
	build_dosbox
	install_package "${MAKE} install" "${WINEBUILDPATH}/${DOSBOXDIR}"
}

#
# orc
#
ORCVER="0.4.16"
ORCFILE="orc-${ORCVER}.tar.gz"
ORCURL="http://code.entropywave.com/download/orc/${ORCFILE}"
ORCSHA1SUM="b67131881e7834b0c820bfba468f668100fb2e91"
ORCDIR="orc-${ORCVER}"
function clean_orc {
	clean_source_dir "${ORCDIR}" "${WINEBUILDPATH}"
}
function get_orc {
	get_file "${ORCFILE}" "${WINESOURCEPATH}" "${ORCURL}"
}
function check_orc {
	check_sha1sum "${WINESOURCEPATH}/${ORCFILE}" "${ORCSHA1SUM}"
}
function extract_orc {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${ORCFILE}" "${WINEBUILDPATH}" "${ORCDIR}"
}
function configure_orc {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${ORCDIR}"
}
function build_orc {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${ORCDIR}"
}
function install_orc {
	# XXX - -O2 opt breaks compile
	PRECFLAGS=${CFLAGS}
	export CFLAGS=$(echo ${CFLAGS} | sed s#-O2##g)
	clean_orc
	extract_orc
	configure_orc
	build_orc
	install_package "${MAKE} install" "${WINEBUILDPATH}/${ORCDIR}"
	export CFLAGS=${PRECFLAGS}
}

#
# libogg
#
LIBOGGVER="1.3.0"
LIBOGGFILE="libogg-${LIBOGGVER}.tar.gz"
LIBOGGURL="http://downloads.xiph.org/releases/ogg/${LIBOGGFILE}"
LIBOGGSHA1SUM="a900af21b6d7db1c7aa74eb0c39589ed9db991b8"
LIBOGGDIR="libogg-${LIBOGGVER}"
function clean_libogg {
	clean_source_dir "${LIBOGGDIR}" "${WINEBUILDPATH}"
}
function get_libogg {
	get_file "${LIBOGGFILE}" "${WINESOURCEPATH}" "${LIBOGGURL}"
}
function check_libogg {
	check_sha1sum "${WINESOURCEPATH}/${LIBOGGFILE}" "${LIBOGGSHA1SUM}"
}
function extract_libogg {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBOGGFILE}" "${WINEBUILDPATH}" "${LIBOGGDIR}"
}
function configure_libogg {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBOGGDIR}"
}
function build_libogg {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBOGGDIR}"
}
function install_libogg {
	clean_libogg
	extract_libogg
	configure_libogg
	build_libogg
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBOGGDIR}"
}

#
# libvorbis
#
LIBVORBISVER="1.3.3"
LIBVORBISFILE="libvorbis-${LIBVORBISVER}.tar.gz"
LIBVORBISURL="http://downloads.xiph.org/releases/vorbis/${LIBVORBISFILE}"
LIBVORBISSHA1SUM="8dae60349292ed76db0e490dc5ee51088a84518b"
LIBVORBISDIR="libvorbis-${LIBVORBISVER}"
function clean_libvorbis {
	clean_source_dir "${LIBVORBISDIR}" "${WINEBUILDPATH}"
}
function get_libvorbis {
	get_file "${LIBVORBISFILE}" "${WINESOURCEPATH}" "${LIBVORBISURL}"
}
function check_libvorbis {
	check_sha1sum "${WINESOURCEPATH}/${LIBVORBISFILE}" "${LIBVORBISSHA1SUM}"
}
function extract_libvorbis {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBVORBISFILE}" "${WINEBUILDPATH}" "${LIBVORBISDIR}"
}
function configure_libvorbis {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${LIBVORBISDIR}"
}
function build_libvorbis {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBVORBISDIR}"
}
function install_libvorbis {
	clean_libvorbis
	extract_libvorbis
	configure_libvorbis
	build_libvorbis
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBVORBISDIR}"
}

#
# libtheora
#
LIBTHEORAVER="1.1.1"
LIBTHEORAFILE="libtheora-${LIBTHEORAVER}.tar.bz2"
LIBTHEORAURL="http://downloads.xiph.org/releases/theora/${LIBTHEORAFILE}"
LIBTHEORASHA1SUM="8dcaa8e61cd86eb1244467c0b64b9ddac04ae262"
LIBTHEORADIR="libtheora-${LIBTHEORAVER}"
function clean_libtheora {
	clean_source_dir "${LIBTHEORADIR}" "${WINEBUILDPATH}"
}
function get_libtheora {
	get_file "${LIBTHEORAFILE}" "${WINESOURCEPATH}" "${LIBTHEORAURL}"
}
function check_libtheora {
	check_sha1sum "${WINESOURCEPATH}/${LIBTHEORAFILE}" "${LIBTHEORASHA1SUM}"
}
function extract_libtheora {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${LIBTHEORAFILE}" "${WINEBUILDPATH}" "${LIBTHEORADIR}"
}
function configure_libtheora {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-examples" "${WINEBUILDPATH}/${LIBTHEORADIR}"
}
function build_libtheora {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LIBTHEORADIR}"
}
function install_libtheora {
	clean_libtheora
	extract_libtheora
	configure_libtheora
	build_libtheora
	install_package "${MAKE} install" "${WINEBUILDPATH}/${LIBTHEORADIR}"
}

#
# gstreamer
#
GSTREAMERBASEVER="0.10"
GSTREAMERVER="${GSTREAMERBASEVER}.36"
GSTREAMERFILE="gstreamer-${GSTREAMERVER}.tar.bz2"
GSTREAMERURL="http://gstreamer.freedesktop.org/src/gstreamer/${GSTREAMERFILE}"
GSTREAMERSHA1SUM="ff95b5316b920e7c2836588bba18fa61395fbd03"
GSTREAMERDIR="gstreamer-${GSTREAMERVER}"
function clean_gstreamer {
	clean_source_dir "${GSTREAMERDIR}" "${WINEBUILDPATH}"
}
function get_gstreamer {
	get_file "${GSTREAMERFILE}" "${WINESOURCEPATH}" "${GSTREAMERURL}"
}
function check_gstreamer {
	check_sha1sum "${WINESOURCEPATH}/${GSTREAMERFILE}" "${GSTREAMERSHA1SUM}"
}
function extract_gstreamer {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GSTREAMERFILE}" "${WINEBUILDPATH}" "${GSTREAMERDIR}"
}
function configure_gstreamer {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS}" "${WINEBUILDPATH}/${GSTREAMERDIR}"
}
function build_gstreamer {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GSTREAMERDIR}"
}
function install_gstreamer {
	clean_gstreamer
	extract_gstreamer
	configure_gstreamer
	build_gstreamer
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GSTREAMERDIR}"
	pushd . >/dev/null 2>&1
	cd ${WINEINCLUDEPATH} || fail_and_exit "could not change into ${WINEINCLUDEPATH}"
	ln -Ffs gstreamer-${GSTREAMERBASEVER}/gst . || fail_and_exit "could not symlink gstreamer-${GSTREAMERBASEVER}/gst to ${WINEINCLUDEPATH}/gst"
	popd
}

#
# gstpluginsbase
#
GSTPLUGINSBASEVER="0.10.36"
GSTPLUGINSBASEFILE="gst-plugins-base-${GSTPLUGINSBASEVER}.tar.bz2"
GSTPLUGINSBASEURL="http://gstreamer.freedesktop.org/src/gst-plugins-base/${GSTPLUGINSBASEFILE}"
GSTPLUGINSBASESHA1SUM="e675401b62a6bf2e5ea966e833afd005a585e978"
GSTPLUGINSBASEDIR="gst-plugins-base-${GSTPLUGINSBASEVER}"
function clean_gstpluginsbase {
	clean_source_dir "${GSTPLUGINSBASEDIR}" "${WINEBUILDPATH}"
}
function get_gstpluginsbase {
	get_file "${GSTPLUGINSBASEFILE}" "${WINESOURCEPATH}" "${GSTPLUGINSBASEURL}"
}
function check_gstpluginsbase {
	check_sha1sum "${WINESOURCEPATH}/${GSTPLUGINSBASEFILE}" "${GSTPLUGINSBASESHA1SUM}"
}
function extract_gstpluginsbase {
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GSTPLUGINSBASEFILE}" "${WINEBUILDPATH}" "${GSTPLUGINSBASEDIR}"
}
function configure_gstpluginsbase {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-examples --enable-experimental --enable-introspection=no" "${WINEBUILDPATH}/${GSTPLUGINSBASEDIR}"
}
function build_gstpluginsbase {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GSTPLUGINSBASEDIR}"
}
function install_gstpluginsbase {
	# XXX - 0.10.31{+?} breaks
	PRECFLAGS=${CFLAGS}
	export CFLAGS=$(echo "${CFLAGS} -Xarch_i386 -O1" | sed 's#-O2##g')
	export CXXFLAGS=${CFLAGS}
	echo "gst-plugins-base compile options: \$CFLAGS = \"${CFLAGS}\", \$CXXFLAGS = \"${CXXFLAGS}\""
	clean_gstpluginsbase
	extract_gstpluginsbase
	configure_gstpluginsbase
	build_gstpluginsbase
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GSTPLUGINSBASEDIR}"
	export CFLAGS=${PRECFLAGS}
	export CXXFLAGS=${CFLAGS}
}

# 
# XXX - GStreamer support
#   gst-plugins-good - gst-plugins-base, orc, others?
#   gst-plugins-ugly - gst-plugins-base, orc, others?
#   gst-plugins-bad - gst-plugins-base, orc, others?
#   ffmpeg - reqs?
#   gst-ffmpeg - gst-plugins-base, orc, ffmpeg, others?
#

#
# cabextract
#
CABEXTRACTVER="1.4"
CABEXTRACTFILE="cabextract-${CABEXTRACTVER}.tar.gz"
CABEXTRACTURL="http://www.cabextract.org.uk/${CABEXTRACTFILE}"
CABEXTRACTSHA1SUM="b1d5dd668d2dbe95b47aad6e92c0b7183ced70f1"
CABEXTRACTDIR="cabextract-${CABEXTRACTVER}"
function clean_cabextract {
	clean_source_dir "${CABEXTRACTDIR}" "${WINEBUILDPATH}"
}
function get_cabextract {
	# XXX - cURL downloads broken :\
	export PRECURLOPTS=${CURLOPTS}
	export CURLOPTS="${CURLOPTS} -A 'Mozilla/5.0'"
	get_file "${CABEXTRACTFILE}" "${WINESOURCEPATH}" "${CABEXTRACTURL}"
	export CURLOPTS=${PRECURLOPTS}
}
function check_cabextract {
	check_sha1sum "${WINESOURCEPATH}/${CABEXTRACTFILE}" "${CABEXTRACTSHA1SUM}"
}
function extract_cabextract {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${CABEXTRACTFILE}" "${WINEBUILDPATH}" "${CABEXTRACTDIR}"
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
# git
#
GITVERSION="1.7.10.3"
GITFILE="git-${GITVERSION}.tar.gz"
GITURL="http://git-core.googlecode.com/files/${GITFILE}"
GITSHA1SUM="172c6ad5a55276213c5e40b83a4c270f6f931b3e"
GITDIR="git-${GITVERSION}"
function clean_git {
	clean_source_dir "${GITDIR}" "${WINEBUILDPATH}"
}
function get_git {
	get_file "${GITFILE}" "${WINESOURCEPATH}" "${GITURL}"
}
function check_git {
	check_sha1sum "${WINESOURCEPATH}/${GITFILE}" "${GITSHA1SUM}"
}
function extract_git {
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${GITFILE}" "${WINEBUILDPATH}" "${GITDIR}"
}
function configure_git {
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX}" "${WINEBUILDPATH}/${GITDIR}"
}
function build_git {
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${GITDIR}"
}
function install_git {
	clean_git
	extract_git
	configure_git
	build_git
	install_package "${MAKE} install" "${WINEBUILDPATH}/${GITDIR}"
}

#
# crossover patch(es)
#
# XXX - patch needed for Codeweavers Crossover Wine sources
# XXX - currently need to be run from the Wine source directory with proper 'patch -pX' level
# XXX - hackity hack hack
#
CROSSOVERPATCHFILES=""
CROSSOVERPATCHSHA1SUMS=""
if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
	CROSSOVERPATCHFILES="no-quartz-wm-workaround.patch"
	CROSSOVERPATCHSHA1SUMS="7c16faa0747dc32d010580407afc371a40418309"
	CROSSOVERPATCHFILEPREFIXSTRIPS="0"
fi
function get_crossover_patches {
	for CROSSOVERPATCHFILE in ${CROSSOVERPATCHFILES} ; do
		CROSSOVERPATCHURL="http://osxwinebuilder.googlecode.com/files/${CROSSOVERPATCHFILE}"
		get_file "${CROSSOVERPATCHFILE}" "${WINESOURCEPATH}" "${CROSSOVERPATCHURL}"
	done
}
function check_crossover_patches {
	CROSSOVERPATCHSUMPOS=0
	for CROSSOVERPATCHFILE in ${CROSSOVERPATCHFILES} ; do
		CROSSOVERPATCHSUMPOS=$((CROSSOVERPATCHSUMPOS+1))
		CROSSOVERPATCHSHA1SUM=$(echo ${CROSSOVERPATCHSHA1SUMS} | cut -f${CROSSOVERPATCHSUMPOS} -d\ )
		check_sha1sum "${WINESOURCEPATH}/${CROSSOVERPATCHFILE}" "${CROSSOVERPATCHSHA1SUM}"
	done
}
function run_crossover_patches {
	CROSSOVERPATCHPOS=0
	for CROSSOVERPATCHFILE in ${CROSSOVERPATCHFILES} ; do
		CROSSOVERPATCHPOS=$((CROSSOVERPATCHPOS+1))
		CROSSOVERPATCHFILEPREFIXSTRIP=$(echo ${CROSSOVERPATCHFILEPREFIXSTRIPS} | cut -f${CROSSOVERPATCHPOS} -d\ )
		echo "attempting to run patch '${CROSSOVERPATCHFILE}' with a prefix strip of '${CROSSOVERPATCHFILEPREFIXSTRIP}'"
		patch -p${CROSSOVERPATCHFILEPREFIXSTRIP} < ${WINESOURCEPATH}/${CROSSOVERPATCHFILE} || fail_and_exit "could not successfully use patch ${CROSSOVERPATCHFILE}"
		echo "command 'patch -p${CROSSOVERPATCHFILEPREFIXSTRIP} < ${WINESOURCEPATH}/${CROSSOVERPATCHFILE}' completed successfully"
	done
}

#
# gecko
#
GECKOVERSIONS="1.0.0-x86.cab 1.1.0-x86.cab 1.2.0-x86.msi 1.3-x86.msi 1.4-x86.msi 1.5-x86.msi"
GECKOSHA1SUMS="afa22c52bca4ca77dcb9edb3c9936eb23793de01 1b6c637207b6f032ae8a52841db9659433482714 6964d1877668ab7da07a60f6dcf23fb0e261a808 acc6a5bc15ebb3574e00f8ef4f23912239658b41 c30aa99621e98336eb4b7e2074118b8af8ea2ad5 07b2bc74d03c885bb39124a7641715314cd3ae71"
function get_gecko {
	for GECKOVERSION in ${GECKOVERSIONS} ; do
		GECKOFILE="wine_gecko-${GECKOVERSION}"
		GECKOURL="http://downloads.sourceforge.net/wine/${GECKOFILE}"
		get_file "${GECKOFILE}" "${WINESOURCEPATH}" "${GECKOURL}"
	done
}
function check_gecko {
	GECKOSUMPOS=0
	for GECKOVERSION in ${GECKOVERSIONS} ; do
		GECKOSUMPOS=$((GECKOSUMPOS+1))
		GECKOFILE="wine_gecko-${GECKOVERSION}"
		GECKOSHA1SUM=$(echo ${GECKOSHA1SUMS} | cut -f${GECKOSUMPOS} -d\ )
		check_sha1sum "${WINESOURCEPATH}/${GECKOFILE}" "${GECKOSHA1SUM}"
	done
}
function install_gecko {
	for GECKOVERSION in ${GECKOVERSIONS} ; do
		GECKOFILE="wine_gecko-${GECKOVERSION}"
		if [ ! -d  "${WINEINSTALLPATH}/share/wine/gecko" ] ; then
			mkdir -p ${WINEINSTALLPATH}/share/wine/gecko || fail_and_exit "could not create directory for Gecko installation"
		fi
		echo "installing ${GECKOFILE} into ${WINEINSTALLPATH}/share/wine/gecko"
		install -m 644 ${WINESOURCEPATH}/${GECKOFILE} ${WINEINSTALLPATH}/share/wine/gecko/${GECKOFILE} || fail_and_exit "could not put the Wine Gecko cab in the proper location"
	done
}

#
# winetricks
#
# always get latest version, install as exectuable
WINETRICKSFILE="winetricks"
#WINETRICKSURL="http://www.kegel.com/wine/${WINETRICKSFILE}"
WINETRICKSURL="http://winetricks.org/${WINETRICKSFILE}"
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
	if [ ${BUILDSTABLE} -eq 1 ] || [ ${BUILDDEVEL} -eq 1 ] ; then
		extract_file "${TARBZ2}" "${WINESOURCEPATH}/${WINEFILE}" "${WINEBUILDPATH}" "${WINEDIR}"
	elif [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		extract_file "${TARGZ}" "${WINESOURCEPATH}/${WINEFILE}" "${WINEBUILDPATH}" "${WINEDIR}"
		# kill the extra source directories
		for CXGAMESEXTRADIR in cxgui freetype loki samba ; do
			if [ -d ${WINEBUILDPATH}/${CXGAMESEXTRADIR} ] ; then
				pushd . >/dev/null 2>&1
				cd ${WINEBUILDPATH}
				rm -rf ${CXGAMESEXTRADIR} || fail_and_exit "could not remove ${WINETAG} extra directory ${WINEBUILDPATH}/${CXGAMESEXTRADIR}"
				popd >/dev/null 2>&1
			fi
		done
	fi
}
function configure_wine {
	EXTRAXMLOPTS=""
	if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		EXTRAXMLOPTS="=native"
		pushd . >/dev/null 2>&1
		cd ${WINEBUILDPATH}/${WINEDIR} || fail_and_exit "could not cd into Wine directory '${WINEBUILDPATH}/${WINEDIR}'"
		run_crossover_patches
		popd >/dev/null 2>&1
	fi
	WINECONFIGUREOPTS=""
	WINECONFIGUREOPTS+="--verbose "
	WINECONFIGUREOPTS+="--${WIN16FLAG}-win16 "
	WINECONFIGUREOPTS+="--disable-win64 "
	WINECONFIGUREOPTS+="--without-capi "
	WINECONFIGUREOPTS+="--without-hal "
	WINECONFIGUREOPTS+="--without-v4l "
	WINECONFIGUREOPTS+="--with-cms "
	WINECONFIGUREOPTS+="--with-coreaudio "
	WINECONFIGUREOPTS+="--with-cups "
	WINECONFIGUREOPTS+="--with-curses "
	WINECONFIGUREOPTS+="--with-fontconfig "
	WINECONFIGUREOPTS+="--with-freetype "
	WINECONFIGUREOPTS+="--with-glu "
	WINECONFIGUREOPTS+="--with-gnutls "
	WINECONFIGUREOPTS+="--with-gphoto "
	WINECONFIGUREOPTS+="--with-gsm "
	WINECONFIGUREOPTS+="--with-jpeg "
	WINECONFIGUREOPTS+="--with-ldap "
	WINECONFIGUREOPTS+="--with-mpg123 "
	WINECONFIGUREOPTS+="--with-openal "
	WINECONFIGUREOPTS+="--with-opengl "
	WINECONFIGUREOPTS+="--with-openssl "
	WINECONFIGUREOPTS+="--with-png "
	WINECONFIGUREOPTS+="--with-pthread "
	WINECONFIGUREOPTS+="--with-sane "
	WINECONFIGUREOPTS+="--with-xml${EXTRAXMLOPTS+${EXTRAXMLOPTS}} "
	WINECONFIGUREOPTS+="--with-xslt "
	WINECONFIGUREOPTS+="--with-x "
	WINECONFIGUREOPTS+="--x-includes=${X11INC} "
	WINECONFIGUREOPTS+="--x-libraries=${X11LIB} "
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${WINECONFIGUREOPTS}" "${WINEBUILDPATH}/${WINEDIR}"
}
function depend_wine {
	build_package "${MAKE} depend" "${WINEBUILDPATH}/${WINEDIR}"
}
function build_wine {
	# CrossOver has some issues building with concurrent make processes for some reason
	if [ ${BUILDSTABLE} -eq 1 ] || [ ${BUILDDEVEL} -eq 1 ] ; then
		build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${WINEDIR}"
	elif [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		build_package "${MAKE}" "${WINEBUILDPATH}/${WINEDIR}"
	fi
}
function install_wine {
	clean_wine
	extract_wine
	configure_wine
	#depend_wine
	build_wine
	install_package "${MAKE} install" "${WINEBUILDPATH}/${WINEDIR}"
	if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		ln -Ffs wineloader ${WINEINSTALLPATH}/bin/wine
	fi
}

#
# get_sources
#   fetches all source packages
#
function get_sources {
	get_xz
	get_libffi
	get_pkgconfig
	get_pkgconfig026
	get_gettext
	get_jpeg
	get_jbigkit
	get_tiff
	get_libpng12
	get_libpng14
	get_libxml2
	get_libxslt
	get_glib
	get_mpg123
	get_gsm
	get_freetype
	get_fontconfig
	get_lcms
	get_lzo
	get_libgpgerror
	get_libgcrypt
	get_gmp
	get_nettle
	get_p11kit
	get_gnutls
	get_unixodbc
	get_libexif
	get_libusb
	get_libusbcompat
	get_gd
	get_libgphoto2
	get_sanebackends
	get_jasper
	get_libicns
	get_sdl
	get_sdlnet
	get_sdlsound
	get_dosbox
	get_orc
	get_libogg
	get_libvorbis
	get_libtheora
	get_gstreamer
	get_gstpluginsbase
	get_cabextract
	get_git
	if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		get_crossover_patches
	fi
	get_gecko
	get_winetricks
	get_wine
}

#
# check_sources
#   checks all source SHA-1 sums
#
function check_sources {
	check_xz
	check_libffi
	check_pkgconfig
	check_pkgconfig026
	check_gettext
	check_jpeg
	check_jbigkit
	check_tiff
	check_libpng12
	check_libpng14
	check_libxml2
	check_libxslt
	check_glib
	check_mpg123
	check_gsm
	check_freetype
	check_fontconfig
	check_lcms
	check_lzo
	check_libgpgerror
	check_libgcrypt
	check_gmp
	check_nettle
	check_p11kit
	check_gnutls
	check_unixodbc
	check_libexif
	check_libusb
	check_libusbcompat
	check_gd
	check_libgphoto2
	check_sanebackends
	check_jasper
	check_libicns
	check_sdl
	check_sdlnet
	check_sdlsound
	check_dosbox
	check_orc
	check_libogg
	check_libvorbis
	check_libtheora
	check_gstreamer
	check_gstpluginsbase
	check_cabextract
	check_git
	if [ ${BUILDCROSSOVER} -eq 1 ] || [ ${BUILDCXGAMES} -eq 1 ] ; then
		check_crossover_patches
	fi
	check_gecko
	check_wine
}

#
# install prereqs
#   extracts, builds and installs prereqs
#
function install_prereqs {
	install_pkgconfig
	install_gettext
	install_xz
	install_libffi
	install_glib
	install_pkgconfig026
	install_jpeg
	install_jbigkit
	install_tiff
	install_libpng12
	#install_libpng14
	install_libxml2
	install_mpg123
	install_gsm
	install_freetype
	install_fontconfig
	install_lcms
	install_lzo
	install_libgpgerror
	install_libgcrypt
	install_gmp
	install_nettle
	install_p11kit
	install_gnutls
	install_libxslt
	install_libexif
	install_libusb
	install_libusbcompat
	install_gd
	install_libgphoto2
	install_sanebackends
	install_jasper
	install_libicns
	install_sdl
	install_sdlnet
	install_orc
	install_libogg
	install_libvorbis
	install_sdlsound
	install_dosbox
	install_libtheora
	install_gstreamer
	install_gstpluginsbase
	install_unixodbc
	install_cabextract
	#install_git
	install_winetricks
	install_gecko
}

#
# build_complete
#   print out a nice informational message when done
#
function build_complete {
	cat << EOF

Successfully built and installed ${WINETAG}!

The installation base directory is:

  ${WINEINSTALLPATH}

You can set the following environment variables to use the new Wine install:

  export DYLD_FALLBACK_LIBRARY_PATH="${WINELIBPATH}:${X11LIB}:/usr/lib"
  export PATH="${WINEBINPATH}:\${PATH}"

Please see http://osxwinebuilder.googlecode.com for more information.
If you notice any bugs, please file an issue and leave a comment.

EOF
}

#
# now that our helper functions are done, run through the actual install
#

# move the install dir out of the way if it exists
if [ ${NOCLEANPREFIX} -eq 1 ] ; then
	echo "--no-clean-prefix set, not moving existing prefix aside"
else 
	if [ -d ${WINEINSTALLPATH} ] ; then
		echo "moving existing prefix ${WINEINSTALLPATH} to ${WINEINSTALLPATH}.PRE-${TIMESTAMP}"
		mv ${WINEINSTALLPATH}{,.PRE-${TIMESTAMP}}
	fi
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

# we're done
build_complete

# exit nicely
exit 0
