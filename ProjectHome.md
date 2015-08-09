# osxwinebuilder #



## Purpose ##
The goal of this project is to provide easy-to-use scripts for cleanly building and installing Wine and its prerequisite software into a self-contained directory hierarchy on Mac OS X.  All building and installation takes place in the user's home directory.  The installation is entirely in user-space, and should not require any write access to system directories, `sudo` or `root` user privileges, or any other form of admin access.

If Xcode/Developer Tools or X11 packages are not installed on the system, you **will** need admin access to get these prerequisites taken care of.  I'd recommend being on good terms with your friendly (or otherwise) sysadmin if that's the case.

The default Wine development version is tracked, and generally updated with a few days of an upstream release. It may be as long as a week occasionally given my busyness in real life. The stable build, and any other builds such as Crossover specific Wine versions, could be broken at any point. However, I'll always try to keep the Wine development version working.

## Caveats ##
You should be comfortable with using a terminal program, as well as launching programs from your shell.  This is a stock Wine install with no pretty GUI or Mac-specific features.  If the idea of running Terminal.app scares you, or if you're allergic to shell, you might check out doh123's excellent [wineskin](http://wineskin.doh123.com/).

But if you need vanilla Wine, this project should get you at least halfway there...

Please note that [MacPorts](http://www.macports.org/), [Fink](http://www.finkproject.org/), [Homebrew](http://github.com/mxcl/homebrew), etc., should be **ignored** by the script.  It should be an entirely self-contained environment, so external software will likely **not** be picked up by the build.  If you've installed versions of included packages using external packaging systems, they may conflict with those built from source.  Furthermore, while I've done my best to avoid compile-time problems, run-time errors may occur if external package management systems are installed. Buyer beware.

As with most free/open source software, there is no expressed warranty or guarantee that this software will work. If your computer splits in two, you get to keep both pieces. If your home directory (or entire operating system) is wiped out due to a script/build malfunction, well I hope you have backups.

Have backups regardless. Multiple backups.

## Requirements ##
You'll need an X11 package installed, preferably one of Apple's builds.  You'll also need a full install of Xcode for compilers, headers, etc., including the X11 development package.

Up-to-date versions of X11 can be grabbed for 10.5/Leopard, 10.6/Snow Leopard and 10.7/Lion from:

http://xquartz.macosforge.org/

Xquartz builds from the above URL have been tested on 10.5, 10.6 and 10.7.  There are a few bugs (namely with the XRender extension) that can be fixed using XQuartz.  While XQuartz on 10.6/10.7 is not strictly necessary, and the stock OS X-provided X11.app should work fine, I would recommend using XQuartz for the simple reason that it's kept more up-to-date and therefore receives bug fixes quicker than the OS packages.

On 10.5, save yourself the time and effort and just install XQuartz straight away.  There are numerous GLX (OpenGL) fixes in XQuartz that should allow graphical programs to work much more reliably.  These fixes will likely never make it into the OS-provided X11 packages.  Please note that any time you install an OS point release or security update on Leopard, you should reinstall the XQuartz package after the updates are run.  This is not necessary on Snow Leopard or Lion.

The XQuartz 2.x series is the current stable release of XQuartz for both Leopard and Snow Leopard.

The developer tools can be installed from your OS X DVD, installed from the Mac app store, or downloaded from:

https://connect.apple.com/ (free registration required)

ccache is built and installed under ~/wine/tools to speed up compilation of requirements.

Around 3GB of disk space is needed during compilation.  The versioned Wine install itself should be around 350MB, and the build directories can be safely removed once Wine is successfully built. The ccache cache directory can be removed as well, but I don't recommend doing so if you plan to keep up to date on builds.

Internet access during the initial part of the build is **required** to download required source packages as well.

### Xcode Versions ###

Xcode versions that have been tested:

| **OS** | **Xcode Release** | **Compiler** |
|:-------|:------------------|:-------------|
| **Mac OS X 10.6 (Snow Leopard)** | Xcode 3.2.6       | Apple GCC 4.2 included with Xcode |
| **Mac OS X 10.7 (Lion)** | Xcode 4.3.2       | Apple GCC 4.2 built via LLVM included with Xcode |
| **OS X 10.8 (Mountain Lion)** | Xcode 4.6.2       | Apple GCC 4.2 built via LLVM included with Xcode |

Xcode 3.2.6 is the last free version available for 10.6, so stick with that if you're on Snow Leopard if at all possible.

Xcode 4.6.x is the current Xcode for Lion and Mountain Lion. If you're encountering build problems, install the latest version and make sure you install/update command line tools as outlined below.

Mac OS X 10.5/Leopard is currently **untested** and I no longer have access to a 10.5 build machine. It may work; it may not. Other combinations of Xcode and compiler versions may or may not work. Please report any successes or failures with version numbers if you have the information handy!

### (Mountain) Lion Considerations ###
On 10.7/Lion and 10.8/Mountain Lion, the command line development tools are necessary. You can install these via:

> Xcode -> Preferences -> Downloads -> Components -> Command Line Tools

You need **at least** the command line tools for your OS. You can download the command line tools only using a free account only on http://developer.apple.com, but installing Xcode from the App Store on Lion+ is likely the easier path for most users.

The Xcode 4.x command line tools from developer.apple.com may be enough to get by; this is untested. On 10.7, the default compilers are llvm-gcc and clang; you'll have to have some setup as "gcc" and "g++" - this should be llvm on a stock Xcode 4.2+ install. To test, simply run a `gcc --version` and `g++ --version` from a command line to see if they are found and run.

On Lion (and currently **only** on Lion and higher), llvm and clang are detected, and a full GCC compiler built for C, C++, Objective-C and Objective-C++. This process takes quite some time, but should result in working compilers in the ~/wine/tools directory. The compiler installation should only have to run once. Subsequent script runs should **not** need to rebuild the compilers. If you have your own toolchain, you can set `GCC` and `GXX` environment variables to the appropriate values - note that **only** Apple-specific GCC is supported at this time.

The above also likely applies to 10.6 with Xcode 4+ as well. My 10.6 test machine will be on Xcode 3.2.6 until it dies though, so please report any findings if available.

## Releases ##
Currently, only releases of source through the Subversion revision control system are available.  Specific versions of Wine may be bundled at some point in the future and be added as either Subversion tags or as .tar.gz/.tar.bz2 archives available from a download section.  For now, stick with Subversion's trunk since it will be up-to-date, warts and all.

## Getting the build script source ##
You can use the **[source](http://code.google.com/p/osxwinebuilder/source/checkout)** tab to see an example of checking source out of subversion trunk.  In a nutshell:

```
mkdir -p ~/wine
cd ~/wine
svn checkout http://osxwinebuilder.googlecode.com/svn/trunk/ osxwinebuilder-read-only
```

## Updating the build script source ##
The checkout process is a one-time operation.  You can now update your source easily at any time by running the following:

```
cd ~/wine/osxwinebuilder-read-only
svn up
```

## Building Wine via the script ##
You can now use the script to build and install Wine into a versioned directory in `~/wine`:

```
cd ~/wine/osxwinebuilder-read-only
./osxwinebuild.sh
```

This will download all required source tarballs and build them; make sure you're connected to a network with public access to the internet at large or the build will fail, as it will be unable to grab the source it needs!

Source packages will be pulled into `~/wine/source/` and individual build directories will be dropped into `~/wine/build/`.  The build script will attempt to create these directories if they don't exist.

Subdirectories under `~/wine/build/` are removed at script run-time, so **do not** store anything valuable there.  If you need to make changes/patch packages, you'll need to work it into the script.  The **clean`_`** script functions can be commented out if necessary.  I've so far shied away from adding a package-wide patching mechanism to the script as it's already far too complicated.  All software is currently installed via standard _configure/make/make install_ methods where possible after removal and extraction of the source directory.  Once the build is complete, you can safely remove everything under `~/wine/build/` to clear up 1GB or more of space.

The initial download/build/install process can take upwards of two hours, or more, even on a fast machine with a decent broadband connection.

## Running Wine ##
The build should complete successfully.  The Wine installation (and all of the prerequisites) will be placed into `~/wine/wine-X.X.X` where **X.X.X** is substituted with a valid version number.  For example, to run Wine 1.5.0, you can set the following environment variables in your terminal program:

```
export DYLD_FALLBACK_LIBRARY_PATH="${HOME}/wine/wine-1.5.0/lib:/usr/X11/lib:/usr/lib"
export PATH="${HOME}/wine/wine-1.5.0/bin:${PATH}"
```

Running `which wine` should show something like the following:

```
which wine
/Users/yourusername/wine/wine-1.5.0/bin/wine
```

Once the build is verified as installed, you can then add the `export` lines above to a shell startup script of your choosing.  Congratulations, you've now built and installed Wine from source!

## Verification ##

You should now have a new, full Wine installed in a versioned directory under your home directory.  You can test functionality by running a couple of test programs.

The `winecfg` program is a GUI tool for setting some common options in Wine:

```
wine winecfg
```

If you've never run Wine before, a new **WINEPREFIX** holding a virtual Windows C: drive will be created under the default `~/.wine` directory.  This folder is hidden from the Finder, but you can access it via Terminal.app or other tools.

To run Wine's [Gecko-based](http://wiki.winehq.org/Gecko) internal web browser, simply type the following into a terminal:

```
wine iexplore
```

You should see the [Wine homepage](http://www.winehq.org/).  At this point, Wine is functional, and you can start off with some simple `winetricks` installs:

[WinetricksOnMacOSX](WinetricksOnMacOSX.md)

## Reporting bugs ##
All software has bugs, and I'd love to know about them.  Please use the **[issues](http://code.google.com/p/osxwinebuilder/issues/list)** tab to report any bugs or problems.

I'm always looking for feedback too.  If there's anything you want to see, just let me know.  I have some ideas for adding Git support, (better) Codeweavers customized Crossover Wine sources, etc.

## License ##
LGPL (GNU Lesser General Public License) v2.1.  Full text available **[here](http://www.gnu.org/licenses/lgpl-2.1.html)**.

## Other software ##
This build relies on other software sources with different licenses; all sources except the GSM library are pulled from public repositories as needed and are not redistributed in any way, binary or otherwise.  The original home for toast/GSM (http://user.cs.tu-berlin.de/~jutta/toast.html) has gone offline.  External software built by the script along with Wine have been documented:

**[OtherSoftware](OtherSoftware.md)**

## Links ##
  * Wine: http://winehq.org
  * Wine wiki: http://wiki.winehq.org, and building on OS X: http://wiki.winehq.org/MacOSX/Building
  * jswindle.com Wine wiki: http://wiki.jswindle.com/index.php/Main_Page
  * winetricks (included): http://wiki.winehq.org/winetricks
  * winezeug: http://winezeug.googlecode.com
  * Apple Developer Tools: http://developer.apple.com/tools/xcode/
  * Xquartz: http://xquartz.macosforge.org/
  * MacPorts: http://www.macports.org/
  * Fink: http://www.finkproject.org/
  * Homebrew: http://github.com/mxcl/homebrew
  * WineBottler: http://winebottler.kronenberg.org/
  * Wineskin: http://wineskin.doh123.com/Information.html