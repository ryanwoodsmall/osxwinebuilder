#!/bin/bash
#
# Compile and install Wine and many prerequisites in a self-contained directory.
#
# Copyright (C) 2009,2010 Ryan Woodsmall <rwoodsmall@gmail.com>
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
	echo "usage: $(basename ${0}) [--help] [--stable] [--devel] [--no-clean-prefix] [--no-clean-source] [--no-rebuild] [--no-reconfigure]"
	echo "    --help: display this help message"
	echo "    --stable: build the stable version of Wine (default)"
	echo "    --devel: build the development version of Wine"
	echo "    --no-clean-prefix: do not move and create a new prefix if one already exists"
	echo "    --no-clean-source: do not remove/extract source if already done"
	echo "    --no-rebuild: do not rebuild packages, just reinstall"
	echo "    --no-reconfigure: do not re-run 'configure' for any packages"
	echo ""
	echo "    Note:"
	echo "      --stable and --devel are mutually exclusive"
	echo "      if both (or neither) are specificed, --stable will be chosen"
}

# options
#   set devel/stable swtiches both to zero, handle below
BUILDSTABLE=0
BUILDDEVEL=0
#   we remove and rebuild everything in a new prefix by default
NOCLEANPREFIX=0
NOCLEANSOURCE=0
NOREBUILD=0
NORECONFIGURE=0
#   cycle through options and set appropriate vars
if [ ${#} -gt 0 ] ; then
	until [ -z ${1} ] ; do
		case ${1} in
			--devel)
				BUILDDEVEL=1
				echo "found --devel option, will build Wine devel version" ; shift ;;
			--stable)
				BUILDSTABLE=1
				echo "found --stable option, will build Wine stable version" ; shift ;;
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
#   stable
export WINESTABLEVERSION="1.2"
export WINESTABLESHA1SUM="dc37a32edb274167990ca7820f92c2d85962e37d"
#   devel
export WINEDEVELVERSION="1.3.1"
export WINEDEVELSHA1SUM="f2e88dd990c553a434b9156c8bfd90583d27c0b8"
#   always build stable by default
if [ ${BUILDSTABLE} -eq 0 ] && [ ${BUILDDEVEL} -eq 0 ] ; then
	BUILDSTABLE=1
fi
#   --devel and --stable are mutually exclusive, default to stable if both are specficied
if [ ${BUILDSTABLE} -eq 1 ] && [ ${BUILDDEVEL} -eq 1 ] ; then
	echo "--devel and --stable options both specified, defaulting to stable"
	BUILDSTABLE=1
	BUILDDEVEL=0
fi
#   set versions and SHA1 sums correctly
if [ ${BUILDSTABLE} -eq 1 ] ; then
	export WINEVERSION="${WINESTABLEVERSION}"
	export WINESHA1SUM="${WINESTABLESHA1SUM}"
elif [ ${BUILDDEVEL} -eq 1 ] ; then
	export WINEVERSION="${WINEDEVELVERSION}"
	export WINESHA1SUM="${WINEDEVELSHA1SUM}"
fi
echo "building Wine verison ${WINEVERSION}"

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
#   XXX - super paranoid checks below!
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
#   GCC 4.0
#: ${CC:="gcc-4.0"}
#: ${CXX:="g++-4.0"}
#   GCC 4.2
#: ${CC:="gcc-4.2"}
#: ${CXX:="g++-4.2"}
#   CLANG/LLVM
#: ${CC:="clang"}
#: ${CC:="llvm-gcc-4.2"}
#: ${CXX:="llvm-g++-4.2"}
#   distcc
#: ${CC:="distcc gcc"}
#: ${CXX:="distcc g++"}
#   ccache
#: ${CC:="ccache gcc"}
#: ${CXX:="ccache g++"}
export CC
export CXX
echo "C compiler set to: \$CC = \"${CC}\""
echo "C++ compiler set to: \$CXX = \"${CXX}\""
#   preprocessor/compiler flags
export CPPFLAGS="-I${WINEINCLUDEPATH} ${OSXSDK+-isysroot $OSXSDK} -I${X11INC}"

# some extra flags based on CPU features
export CPUFLAGS=""
# XXX - no distcc,clang,llvm support yet!
# some gcc-specific flags
# a note:
#   all versions of GCC running on Darwin x86/x86_64 10.4+ require GCC 4.0+
#   all versions *should* have support for the P4 "nocona" mtune option
#   all *real* Mac hardware should support SSE3 or better
#   all of the above are true for the dev kit up to the most recent Macs
#   that said, don't know how much "optimization" below is going to help
export USINGGCC=$(echo ${CC} | egrep "(^|/)gcc" | wc -l | tr -d " ")
if [ ${USINGGCC} -eq 1 ] ; then
	# gcc versions
	export GCCVER=$(${CC} --version | head -1 | awk '{print $3}')
	export GCCMAJVER=$(echo ${GCCVER} | cut -d\. -f 1)
	export GCCMINVER=$(echo ${GCCVER} | cut -d\. -f 2)
	# grab all SSE & MMX flags from the CPU feature set
	export CPUFLAGS+=$(sysctl -n machdep.cpu.features | tr "[:upper:]" "[:lower:]" | tr " " "\n" | sed s#^#-m#g | egrep -i "(sse|mmx)" | sort -u | xargs echo)
	# this should always be true, but being paranoid never hurt anyone
	if echo $CPUFLAGS | grep \\-msse >/dev/null 2>&1
	then
		export CPUFLAGS+=" -mfpmath=sse"
	fi
	# set the mtune on GCC based on version
	# should never need to check for GCC <4, but why not?
	if [ ${GCCMAJVER} -eq 4 ] ; then
		# use p4/nocona on GCC 4.0... ugly
		if [ ${GCCMINVER} -eq 0 ] ; then
			export CPUFLAGS+=" -mtune=nocona"
			# no SSE4+ w/4.0
			export CPUFLAGS=$(echo ${CPUFLAGS} | tr " " "\n" | sort -u | grep -vi sse4 | xargs echo)
			# and no SSSE3 on Xcode 2.5; should be gcc 4.0, builds in the 53xx series
			${CC} --version | grep -i "build 53" >/dev/null 2>&1
			if [ $? == 0 ] ; then
				export CPUFLAGS=$(echo ${CPUFLAGS} | tr " " "\n" | sort -u | grep -vi ssse3 | xargs echo)
			fi
		fi
		# use native on 4.2+
		if [ ${GCCMINVER} -ge 2 ] ; then
			export CPUFLAGS+=" -mtune=native"
		fi
	fi
fi
# set our CFLAGS to something useful, and specify we should be using 32-bit
export CFLAGS="-g -O2 -arch i386 -m32 ${CPUFLAGS} ${OSXSDK+-isysroot $OSXSDK} ${OSXVERSIONMIN+-mmacosx-version-min=$OSXVERSIONMIN} ${CPPFLAGS}"
export CXXFLAGS=${CFLAGS}

# linker flags
#   always prefer our Wine install path's lib dir
#   set the sysroot if need be
export LDFLAGS="-L${WINELIBPATH} ${OSXSDK+-isysroot $OSXSDK} -L${X11LIB} -framework CoreServices -lz -L${X11LIB} -lGL -lGLU"

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

# extract commands
#   currently we only have gzip/bzip2 tar files
export TARGZ="tar -zxvf"
export TARBZ2="tar -jxvf"

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
	configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --disable-java --disable-native-java --without-emacs --without-git" "${WINEBUILDPATH}/${GETTEXTDIR}"
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
JPEGVER="8b"
JPEGFILE="jpegsrc.v${JPEGVER}.tar.gz"
JPEGURL="http://www.ijg.org/files/${JPEGFILE}"
JPEGSHA1SUM="15dc1939ea1a5b9d09baea11cceb13ca59e4f9df"
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
	if [ ${NOCLEANPREFIX} -eq 1 ] ; then
		echo "--no-clean-prefix, manually removing libjbig symlinks"
		if [ -L ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib ] ; then
			unlink ${WINELIBPATH}/libjbig.${JBIGKITMAJOR}.dylib || fail_and_exit "could not remove existing libjbig symbolic link"
		fi
		if [ -L ${WINELIBPATH}/libjbig.dylib ] ; then
			unlink ${WINELIBPATH}/libjbig.dylib || fail_and_exit "could not remove existing libjbig symbolic link"
		fi
	fi
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
TIFFVER="3.9.4"
TIFFFILE="tiff-${TIFFVER}.tar.gz"
TIFFURL="http://download.osgeo.org/libtiff/${TIFFFILE}"
TIFFSHA1SUM="a4e32d55afbbcabd0391a9c89995e8e8a19961de"
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
# libpng
#
LIBPNGVER="1.4.3"
#LIBPNGVER="1.2.44"
LIBPNGFILE="libpng-${LIBPNGVER}.tar.gz"
LIBPNGURL="http://downloads.sourceforge.net/libpng/${LIBPNGFILE}"
# 1.4.x SHA1 sum
LIBPNGSHA1SUM="dd56c9ecef2d41aa991740a3da6f136412e3b077"
# 1.2.x SHA1 sum
#LIBPNGSHA1SUM="776bb8e42d86bd71ae58e0d96f85472c1d63beeb"
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${LIBPNGFILE}" "${WINEBUILDPATH}" "${LIBPNGDIR}"
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
LIBXML2VER="2.7.7"
LIBXML2FILE="libxml2-${LIBXML2VER}.tar.gz"
LIBXML2URL="ftp://xmlsoft.org/libxml2/${LIBXML2FILE}"
LIBXML2SHA1SUM="8592824a2788574a172cbddcdc72f734ff87abe3"
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
# XXX - CFLAGS may be fixed in 1.10/1.11 series - test
MPG123VER="1.12.3"
MPG123FILE="mpg123-${MPG123VER}.tar.bz2"
MPG123URL="http://downloads.sourceforge.net/mpg123/${MPG123FILE}"
MPG123SHA1SUM="5e92d3c918f6095264089f711a9f38a5d2168b31"
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
# XXX - GSM is a HUGE HACK on OS X... and it may or may not work.
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
	if [ ${NOCLEANPREFIX} -eq 1 ] ; then
		echo "--no-clean-prefix, manually removing libgsm symlinks"
		if [ -L ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib ] ; then
			unlink ${WINELIBPATH}/libgsm.${GSMMAJOR}.dylib || fail_and_exit "could not remove existing libgsm symbolic link"
		fi
		if [ -L ${WINELIBPATH}/libgsm.dylib ] ; then
			unlink ${WINELIBPATH}/libgsm.dylib || fail_and_exit "could not remove existing libgsm symbolic link"
		fi
	fi
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
FREETYPEVER="2.4.2"
FREETYPEFILE="freetype-${FREETYPEVER}.tar.bz2"
FREETYPEURL="http://downloads.sourceforge.net/freetype/freetype2/${FREETYPEFILE}"
FREETYPESHA1SUM="cc257ceda2950b8c80950d780ccf3ce665a815d1"
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
	# turn on nice but patented hinting
	# XXX - not necessary with 2.4+
	#if [ ! -f include/freetype/config/ftoption.h.unpatented_hinting ] ; then
	#	sed -i.unpatented_hinting \
	#		's#\#define TT_CONFIG_OPTION_UNPATENTED_HINTING#/\* \#define TT_CONFIG_OPTION_UNPATENTED_HINTING \*/#g' \
	#		include/freetype/config/ftoption.h || fail_and_exit "cound not unconfigure TT_CONFIG_OPTION_UNPATENTED_HINTING for freetype"
	#fi
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
	extract_file "${TARGZ}" "${WINESOURCEPATH}/${FONTCONFIGFILE}" "${WINEBUILDPATH}" "${FONTCONFIGDIR}"
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
# lcms2
#
LCMS2VER="2.0"
LCMS2FILE="lcms2-${LCMS2VER}.tar.gz"
LCMS2URL="http://downloads.sourceforge.net/lcms/${LCMS2FILE}"
LCMS2SHA1SUM="c204158d0b4b15d918664750fcd5579f1347a38d"
LCMS2DIR="lcms-${LCMS2VER}"
function clean_lcms2 {
        clean_source_dir "${LCMS2DIR}" "${WINEBUILDPATH}"
}
function get_lcms2 {
        get_file "${LCMS2FILE}" "${WINESOURCEPATH}" "${LCMS2URL}"
}
function check_lcms2 {
        check_sha1sum "${WINESOURCEPATH}/${LCMS2FILE}" "${LCMS2SHA1SUM}"
}
function extract_lcms2 {
        extract_file "${TARGZ}" "${WINESOURCEPATH}/${LCMS2FILE}" "${WINEBUILDPATH}" "${LCMS2DIR}"
}
function configure_lcms2 {
        configure_package "${CONFIGURE} ${CONFIGURECOMMONPREFIX} ${CONFIGURECOMMONLIBOPTS} --with-jpeg --with-tiff --with-zlib" "${WINEBUILDPATH}/${LCMS2DIR}"
}
function build_lcms2 {
        build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${LCMS2DIR}"
}
function install_lcms2 {
        clean_lcms2
        extract_lcms2
        configure_lcms2
        build_lcms2
        # lcms2 v2.0 install-sh is not executable
        pushd . >/dev/null 2>&1
        cd ${WINEBUILDPATH}/${LCMS2DIR} || fail_and_exit "could not cd to ${WINEBUILDPATH}/${LCMS2DIR}"
        chmod 755 install-sh || fail_and_exit "could not set exec permissions on 'install-sh' for LCMS2"
        popd >/dev/null 2>&1
        install_package "${MAKE} install" "${WINEBUILDPATH}/${LCMS2DIR}"
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
LIBGPGERRORVER="1.9"
LIBGPGERRORFILE="libgpg-error-${LIBGPGERRORVER}.tar.bz2"
LIBGPGERRORURL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${LIBGPGERRORFILE}"
LIBGPGERRORSHA1SUM="6836579e42320b057a2372bbcd0325130fe2561e"
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
LIBGCRYPTVER="1.4.6"
LIBGCRYPTFILE="libgcrypt-${LIBGCRYPTVER}.tar.bz2"
LIBGCRYPTURL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/${LIBGCRYPTFILE}"
LIBGCRYPTSHA1SUM="445b9e158aaf91e24eae3d1040c6213e9d9f5ba6"
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
GNUTLSVER="2.10.1"
GNUTLSFILE="gnutls-${GNUTLSVER}.tar.bz2"
GNUTLSURL="ftp://ftp.gnu.org/pub/gnu/gnutls/${GNUTLSFILE}"
GNUTLSSHA1SUM="507ff8ad7c1e042f8ecaa4314f32777e74caf0d3"
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
LIBUSBVER="1.0.8"
LIBUSBFILE="libusb-${LIBUSBVER}.tar.bz2"
LIBUSBURL="http://downloads.sourceforge.net/libusb/${LIBUSBFILE}"
LIBUSBSHA1SUM="5484397860f709c9b51611d224819f8ed5994063"
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
LIBUSBCOMPATVER="0.1.3"
LIBUSBCOMPATFILE="libusb-compat-${LIBUSBCOMPATVER}.tar.bz2"
LIBUSBCOMPATURL="http://downloads.sourceforge.net/libusb/${LIBUSBCOMPATFILE}"
LIBUSBCOMPATSHA1SUM="d5710d5bc4b67c5344e779475b76168c7ccc5e69"
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
GDURL="http://www.libgd.org/releases/${GDFILE}"
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
LIBGPHOTO2VER="2.4.10"
LIBGPHOTO2FILE="libgphoto2-${LIBGPHOTO2VER}.tar.bz2"
LIBGPHOTO2URL="http://downloads.sourceforge.net/gphoto/libgphoto/${LIBGPHOTO2FILE}"
LIBGPHOTO2SHA1SUM="0fbbcfdfe13c3cf128505e3079faf55407b647c5"
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
SANEBACKENDSVER="1.0.21"
SANEBACKENDSFILE="sane-backends-${SANEBACKENDSVER}.tar.gz"
SANEBACKENDSURL="ftp://ftp.sane-project.org/pub/sane/sane-backends-${SANEBACKENDSVER}/${SANEBACKENDSFILE}"
SANEBACKENDSSHA1SUM="4a2789ea9dae1ece090d016abd14b0f2450d9bdb"
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
}
function build_sanebackends {
	# XXX - 'make -j#' fails for #>1 on OS X <10.6/sane-backends 1.0.21.
	# XXX - work around by running a single job for now. dirty, ugh.
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
# cabextract
#
CABEXTRACTVER="1.3"
CABEXTRACTFILE="cabextract-${CABEXTRACTVER}.tar.gz"
CABEXTRACTURL="http://www.cabextract.org.uk/${CABEXTRACTFILE}"
CABEXTRACTSHA1SUM="112469b9e58497a5cfa2ecb3d9eeb9d3a4151c9f"
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
GITVERSION="1.7.2.2"
GITFILE="git-${GITVERSION}.tar.bz2"
GITURL="http://kernel.org/pub/software/scm/git/${GITFILE}"
GITSHA1SUM="0cc1caba421a2af5f8e3b9648a6230ea07c60bee"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${GITFILE}" "${WINEBUILDPATH}" "${GITDIR}"
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
# always get latest version, install as exectuable
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
# wisotool
#
# always get latest version, install as exectuable
WISOTOOLFILE="wisotool"
WISOTOOLURL="http://winezeug.googlecode.com/svn/trunk/${WISOTOOLFILE}"
function get_wisotool {
	# always get wisotool
	pushd . >/dev/null 2>&1
	cd ${WINESOURCEPATH} || fail_and_exit "could not cd to the Wine source repo path"
	echo "downloading ${WISOTOOLURL} to ${WINESOURCEPATH}/${WISOTOOLFILE}"
	${CURL} ${CURLOPTS} -o ${WISOTOOLFILE}.${TIMESTAMP} ${WISOTOOLURL}
	if [ $? == 0 ] ; then
		if [ -f ${WISOTOOLFILE} ] ; then
			mv ${WISOTOOLFILE} ${WISOTOOLFILE}.PRE-${TIMESTAMP}
		fi
		mv ${WISOTOOLFILE}.${TIMESTAMP} ${WISOTOOLFILE}
	fi
	popd >/dev/null 2>&1
}
function install_wisotool {
	if [ -f "${WINESOURCEPATH}/${WISOTOOLFILE}" ] ; then
		echo "installing ${WISOTOOLFILE} into ${WINEBINPATH}"
		install -m 755 ${WINESOURCEPATH}/${WISOTOOLFILE} ${WINEBINPATH}/${WISOTOOLFILE} || echo "could not install install wisotool to ${WINEBINPATH}/${WISOTOOLFILE} - not fatal, install manually"
	fi
}

#
# build wine, finally
#
WINEVER=${WINEVERSION}
WINEFILE="wine-${WINEVER}.tar.bz2"
WINEURL="http://downloads.sourceforge.net/wine/${WINEFILE}"
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
	extract_file "${TARBZ2}" "${WINESOURCEPATH}/${WINEFILE}" "${WINEBUILDPATH}" "${WINEDIR}"
}
function configure_wine {
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
	WINECONFIGUREOPTS+="--with-xml "
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
	build_package "${CONCURRENTMAKE}" "${WINEBUILDPATH}/${WINEDIR}"
}
function install_wine {
	clean_wine
	extract_wine
	configure_wine
	#depend_wine
	build_wine
	install_package "${MAKE} install" "${WINEBUILDPATH}/${WINEDIR}"
}

#
# get_sources
#   fetches all source packages
#
function get_sources {
	get_pkgconfig
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
	#get_lcms2
	get_lzo
	get_libgpgerror
	get_libgcrypt
	get_gnutls
	get_unixodbc
	get_libexif
	get_libusb
	get_libusbcompat
	get_gd
	get_libgphoto2
	get_sanebackends
	get_cabextract
	get_git
	get_gecko
	get_winetricks
	get_wisotool
	get_wine
}

#
# check_sources
#   checks all source SHA-1 sums
#
function check_sources {
	check_pkgconfig
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
	#check_lcms2
	check_lzo
	check_libgpgerror
	check_libgcrypt
	check_gnutls
	check_unixodbc
	check_libexif
	check_libusb
	check_libusbcompat
	check_gd
	check_libgphoto2
	check_sanebackends
	check_cabextract
	check_git
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
	#install_lcms2
	install_lzo
	install_libgpgerror
	install_libgcrypt
	install_gnutls
	install_libexif
	install_libusb
	install_libusbcompat
	install_gd
	install_libgphoto2
	install_sanebackends
	install_unixodbc
	install_cabextract
	install_git
	install_winetricks
	install_wisotool
	install_gecko
}

#
# build_complete
#   print out a nice informational message when done
#
function build_complete {
    cat << EOF

Successfully built and installed Wine version ${WINEVERSION}!

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
