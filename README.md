<img src="https://github.com/nsf-name/lufsa/raw/main/Lufsa-icon.png" width="250" align="right"/>

### Lufsa

*xteddy port to modern macOS*

`lufsa` is a port of the X11 app `xteddy` to modern macOS. The original page for `xteddy` is viewable [by clicking here](https://itn-web.it.liu.se/~stegu76/xteddy/index.html). I recreated this because it doesn't compile on macOS anymore (no X11 libraries and no X11-Quartz bridge these days), I wanted to learn how `xcodegen` and AppKit work with a simple project, and reimplementing `xteddy` is a good way to practice using AppKit/SwiftUI's stranger features.

By default, `lufsa` opens to an image of the classic `xteddy` teddy bear. However, it can do a lot more, since you can use it as something like Sticky Notes but for any image! Simply select an image of your choice in the menu bar, and you can place it anywhere you'd like on your desktop.

## Building
On a macOS 15.0 or newer system, run the following:
```
$ git clone https://github.com/nsf-name/lufsa lufsa && cd lufsa
$ xcodegen generate
$ make build
```
After a build, run `make clean`.

## License

This app is licensed under GPL v2.0 just like the original, which was written by [Professor Stefan Gustavson at Linköping University](https://www.itn.liu.se/~stegu76/) between 1994-1997. I named this rewrite `lufsa` because that's the name of the [original teddy bear used in `xteddy`](https://linuxgazette.net/122/TWDT.html#nottag.2). Richard Neill added the additional images to the Debian port of `xteddy`, which are also bundled with this program.

The app icon is licensed CC-BY-4.0 and the bear image is taken from the [Twitter Color Emoji](https://github.com/13rac1/twemoji-color-font) font.
