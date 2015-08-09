# Other Software #

This project builds a number of other packages as prerequisites of Wine.  Some useful links:

  * http://wiki.winehq.org/MacOSX/Building - Mac OS X-specific
  * http://wiki.winehq.org/Recommended_Packages - Mostly for Linux/BSD/Solaris, but still useful

I will attempt to keep this page updated with every Subversion check in, but svn commit messages may be more reliable.  License information below is based on both websites and included licensing/copyright/etc. files.

| **Project** | **Version** | **Home** | **License** | **Other Info** |
|:------------|:------------|:---------|:------------|:---------------|
| cabextract  | 1.4         | http://www.cabextract.org.uk/ | GPL         | used by winetricks |
| ccache      | 3.1.10      | http://ccache.samba.org/ | GPL         | cache compiler results |
| DOSBox      | 0.74        | http://www.dosbox.com/ | GPL         | DOS support for Wine |
| Fontconfig  | 2.9.0       | http://www.fontconfig.org/wiki/ | copyright Keith Packard | font configurations for Wine |
| FreeType    | 2.4.9       | http://freetype.sourceforge.net/ | GPL/BSD     | font rendering in Wine; patented hinting and subpixel rendering enabled |
| GCC         | 4.2.1 (Apple 5666.3) | http://opensource.apple.com/tarballs/gcc/ | GPL         | GNU Compiler Collection for Apple Mac OS X (Lion and newer for now) |
| GD          | 2.0.36RC1   | http://www.libgd.org/, https://bitbucket.org/pierrejoye/gd-libgd | BSD-like    | image manipulation support for libgphoto2 |
| gecko       | varies      | http://wiki.winehq.org/Gecko, https://developer.mozilla.org/en/Gecko | Mozilla tri-license (MPL/GPL/LGPL) | used for HTML rendering in Wine |
| gettext     | 0.18.1.1    | http://www.gnu.org/software/gettext/ | LGPL/GPL/GFDL | used for translations |
| Git         | 1.7.10.3    | http://git-scm.com/ | GPL         | not used (yet) |
| GLib        | 2.32.3      | http://www.gtk.org, http://library.gnome.org/devel/glib/stable/ | LGPL        | GStreamer prereq |
| gmp         | 5.0.5       | http://gmplib.org/ | LGPL        | nettle support |
| GnuTLS      | 2.12.19     | http://www.gnu.org/software/gnutls/ | LGPL/GPL    | used for Wine's secure channel support |
| GStreamer   | 0.10.36     | http://gstreamer.freedesktop.org/ | LGPL        | multimedia streaming/pipelining |
| gst-plugins-base | 0.10.36     | http://gstreamer.freedesktop.org/modules/ | LGPL/GPL (plus whatever plugins themselves use) | GStreamer base plugins |
| JasPer      | 1.900.1     | http://www.ece.uvic.ca/~mdadams/jasper/ | JasPer-2.0  | JPEG-2000 support for libicns |
| JBIG-KIT    | 2.0         | http://www.cl.cam.ac.uk/~mgk25/jbigkit/ | GPL         | used by tiff   |
| jpeg        | 8d          | http://www.ijg.org/ | Independent JPEG Group, copyright Thomas G. Lane, Guido Vollbeding | JPEG support in Wine |
| lcms        | 1.19/2.5    | http://www.littlecms.com/ | copyright Marti Maria Saguer, MIT license | used for color management in Wine |
| libexif     | 0.6.20      | http://libexif.sourceforge.net/ | LGPL        | used by libgphoto2 |
| libffi      | 3.0.11      | http://sourceware.org/libffi/ | something liberal | foreign function interface for glib |
| libgcrypt   | 1.5.0       | http://www.gnupg.org/ | GPL         | used by GnuTLS |
| libgpg-error | 1.10        | http://www.gnupg.org/ | GPL         | used by GnuTLS |
| libgphoto2  | 2.4.14      | http://www.gphoto.org/ | LGPL        | used for imaging/camera support in Wine |
| libicns     | 0.8.0       | http://icns.sourceforge.net/ | LGPL        | icns file support |
| libogg      | 1.3.0       | http://www.xiph.org/ogg/ | BSD         | Ogg container format (gst-plugins-base) |
| libpng      | 1.2.49      | http://www.libpng.org/ | libpng license | PNG support in Wine |
| libtheora   | 1.1.1       | http://theora.org/ | BSD         | Theora video compression format (gst-plugins-base) |
| libtiff     | 3.9.6       | http://www.remotesensing.org/libtiff/, http://libtiff.maptools.org/ | coypright Sam Leffler, Silicon Graphics, Inc | used for TIFF support in Wine |
| libtool     | 2.4.2       | http://www.gnu.org/software/libtool/ | GPL         | provides libltdl for Lion+ |
| libusb      | 1.0.9       | http://www.libusb.org/ | LGPL        | used by sane-backends |
| libusb-compat | 0.1.4       | http://www.libusb.org/ | LGPL        | used by libgphoto2 |
| libvorbis   | 1.3.3       | http://www.xiph.org/vorbis/ | BSD         | Vorbis audio compression format (gst-plugins-base) |
| libxml2     | 2.8.0       | http://xmlsoft.org/ | copyright Daniel Veillard | XML support in Wine |
| libxslt     | 1.1.26      | http://xmlsoft.org/ | copyright Thomas Broyer, Charlie Bozeman and Daniel Veillard | XSL/XSLT support in Wine |
| lzo         | 2.06        | http://www.oberhumer.com/opensource/lzo/ | GPL         | used by GnuTLS |
| mono        | varies      | http://wiki.winehq.org/Mono | GPL/LGPL/MIT | Mono Wine package for .Net support |
| mpg123      | 1.14.2      | http://www.mpg123.de/ | LGPL        | used for MP3/audio support in Wine |
| nettle      | 2.4         | http://www.lysator.liu.se/~nisse/nettle/ | LGPL        | crypto library used by gnutls |
| orc         | 0.4.16      | http://code.entropywave.com/projects/orc/ | Copyright David A. Schleef, Makoto Matsumoto, Takuji Nishimura| Oil Runtime Compiler - used for GStreamer plugins|
| p11-kit     | 0.12        | http://p11-glue.freedesktop.org/ | BSD 3 clause | PKCS#11 support for gnutls |
| pkg-config  | 0.25/0.26   | http://pkg-config.freedesktop.org/wiki/ | GPL         | used by multiple packages |
| SANE Backends | 1.0.23      | http://www.sane-project.org/ | GPL         | scanner/imaging access in Wine |
| SDL         | 1.2.15      | http://www.libsdl.org/ | LGPL        | cross-platform media library, required for DOSBox |
| SDL\_net    | 1.2.8       | http://www.libsdl.org/projects/SDL_net/ | LGPL        | networking for SDL |
| SDL\_sound  | 1.0.3       | http://icculus.org/SDL_sound/ | GPL         | sound library for SDL |
| toast (GSM) | 1.0.13      | http://www.quut.com/gsm/ | see http://osxwinebuilder.googlecode.com/files/gsm-COPYRIGHT | used by Wine for audio encode/decode |
| unixODBC    | 2.3.0       | http://www.unixodbc.org/ | LGPL        | used for native ODBC bridge to Wine |
| winetricks  | varies      | http://code.google.com/p/winetricks/ | LGPL        | quick install script for some Windows programs |
| xz          | 5.0.3       | http://tukaani.org/xz/ | public domain, GPL, LGPL | XZ/LZMA archive support |
| Wine        | 1.6.2 (stable), 1.7.38 (development) | http://www.winehq.org/ | LGPL        | Wine is used for Wine, right? |
| CodeWeavers CrossOver Wine sources | 14.0.3      | http://www.codeweavers.com/products/source | LGPL        | CodeWeavers builds custom Wine versions for stability and performance purposes |