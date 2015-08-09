# Winetricks #

[Winetricks](http://wiki.winehq.org/winetricks) is a nice little program that makes installing a few commonly-used components into a new [Wine prefix](http://wiki.jswindle.com/index.php/Wine_Prefixes) very simple.  There are a few nice winetricks you can use to make your Wine environment a little nicer.  All of the examples below should be run from a terminal after installing Wine.  The `winetricks` and `wine` programs need to be in your path as well.  You can verify this with:

```
which wine
which winetricks
```

The commands above should output the full paths to the program executables.

# Examples #

To simply get a list of what winetricks can do for you:
```
winetricks --help
```

To set the Wine "soundcard" to Core Audio output, you can run:
```
winetricks sound=coreaudio
```

To enable [ClearType](http://en.wikipedia.org/wiki/ClearType)-style font smoothing in programs running under Wine:
```
winetricks allfonts fontfix fontsmooth-rgb
```

For Windows Firefox:
```
winetricks firefox
```

And for IE 6:
```
winetricks ie6
```
IE 7:
```
winetricks ie7
```

Install Windows versions of Adobe's Flash player:
```
winetricks flash
```

Valve's Steam was recently added to `winetricks` as well!
```
winetricks steam
```

Disable the GUI dialog box that pops up on a program crash:
```
winetricks nocrashdialog
```

# Updating only winetricks #

There are occasionally `winetricks` updates.  To check your `winetricks` version, you can run:

```
winetricks -V
```

You can backup the current `winetricks` script, then grab a newer version and replace what's currently in your path with the commands:

```
cp $(which winetricks){,`date '+%Y%m%d%H%M%S'`}
curl -kLo $(which winetricks) http://www.kegel.com/wine/winetricks
winetricks -V
```