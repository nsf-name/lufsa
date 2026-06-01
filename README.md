<img src="https://github.com/nsf-name/lufsa/raw/main/Lufsa-icon.png" width="250" align="right"/>

### Lufsa: *xteddy port to modern macOS*

`lufsa` is a port of the X11 app `xteddy` to modern macOS. The original page for `xteddy` is viewable [by clicking here](https://itn-web.it.liu.se/~stegu76/xteddy/index.html). I recreated this because it doesn't compile on macOS anymore (no X11 libraries and no X11-Quartz bridge these days), I wanted to learn how `xcodegen` and AppKit work with a simple project, and reimplementing `xteddy` is a good way to practice using AppKit/SwiftUI's stranger features.

By default, `lufsa` includes all the images bundled with the classic `xteddy` teddy bear, which can be opened via the menu bar. However, it can do a lot more, since you can use it like Sticky Notes but for any image! Simply select an image of your choice in the menu bar, and you can place it anywhere you'd like on your desktop, with the following settings:
- Remove or add borders
- Semi-transparent windows
- Pixel-perfect mode
- Floating window mode
It is compatible with any image type that Preview can read. To my knowledge, `lufsa` is the only macOS image viewer that has all the same window functionality of Sticky Notes. So if you use Sticky Notes as much as I do, then maybe you'll find this useful as well! 

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

## Ideas

Things that might go into a future release, or if requested:
- Layout restoration
- Drag and drop functionality
- Support for more image types
- Pinch/zoom images in-frame
- PDF viewing support
- Port to Wayland on Linux (rewrite in Rust?)
