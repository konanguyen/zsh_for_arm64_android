# Zsh for Arm64 Devices

## Overview

Zsh is a shell designed for interactive use, although it is also a powerful scripting language. Many of the useful features of bash, ksh, and tcsh were incorporated into zsh; many original features were added. See the [user guide](http://zsh.sourceforge.net/Guide/zshguide.html) or the [manual](http://zsh.sourceforge.net/Doc/) for what makes zsh useful.

This repository cross-compiles zsh with the official Android NDK toolchain and packages the result as a [Magisk](https://github.com/topjohnwu/Magisk) / [KernelSU](https://kernelsu.org/) module. It is based on the original module by [Part Cyborg](https://github.com/partcyborg/zsh_arm64_magisk).

## Compatibility

* arm64 (aarch64) devices only.
* Android 6.0+ (API 23), which matches the minimum Android version recent Magisk releases support.
* Magisk v20.4+ — the zip uses the official module layout (`customize.sh`, embedded installer stub).
* KernelSU — installable too. Because the module overlays `/system`, a mounting metamodule (e.g. `meta-overlayfs`) must be installed for the overlay to take effect.
* zsh 5.9 statically linked against ncurses 6.5, with common terminal types (xterm, screen, tmux, rxvt, alacritty, foot, ...) compiled in as terminfo fallbacks, so no terminfo database is required on the device.

## Installation

Flash the zip in the Magisk app or a KernelSU manager. Zsh is installed to `/system/xbin/zsh`; run it at any time from a terminal emulator or an adb session by typing `zsh`.

If you run zsh as root, a home directory is created for you at `/data/local/root`; run as the system user, one is created at `/data/local/system` (this requires `ro.secure=0`). Regular apps don't have sufficient privileges to use this install — if you want zsh with app permissions, use [Termux](https://wiki.termux.com/wiki/Main_Page).

## Building from source

Requirements: an [Android NDK](https://developer.android.com/ndk) (r29 or newer; the default path assumes `~/Android/Sdk/ndk/29.0.14206865`), GNU make, wget, zip, and a host C compiler — the host compiler builds the `tic` tool used to embed terminfo fallback entries into the cross-compiled ncurses.

```
make                               # download sources, build, package out/zsh_arm64-<version>.zip
make NDK=/path/to/android-ndk-r29  # use an NDK at a custom location
make clean                         # remove build/work
make distclean                     # also remove built zips
```

## CI

`.github/workflows/build.yml` builds the module on every tag push, uploads the zip as a build artifact, and attaches it to the GitHub release for that tag.

## License

The bundled zsh (binary, startup files, and completion/function scripts) is distributed under the [licence of the zsh project](https://github.com/zsh-users/zsh/blob/master/LICENCE), reproduced verbatim in [LICENSE](LICENSE). None of the shipped zsh functions carry the GPL provisions mentioned in that file, so the licence above covers the whole distribution. The build scripts in this repository are provided under the same permissive terms. This module is based on the original work by Part Cyborg.

## Changelog

v1.5 - 11/15/2026
* Update zsh to 5.9 and link it against a statically built ncurses 6.5 (built-in terminfo fallbacks, no terminfo database required on device).
* Build with the Android NDK (bionic) instead of a static glibc cross toolchain.
* Modernize the module layout for current Magisk (>= v20.4) and KernelSU: `customize.sh` replaces the legacy `install.sh`/`common/` scripts, and `META-INF/com/google/android/update-binary` is the official installer stub.
* Add LICENSE (the zsh licence) and a CI workflow that builds releases on tag push.

v1.2 - 8/07/2019
* Update README [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/670908e73f5e9ebbd36cfe30775a9139f6ed0db0)
* Move the README file to the project root. [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/dc6ad8602a9debf5efe7a80e8cb3af7cba4e60a9)

v1.1 - 8/05/2019
* Minor bugfixes and cleanups [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/b8e842ff58ddc431b976eb1bbc32df0b7df11578)
* Refactor the build process [2/2]. [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/07f8dd8f9f240037348a4bf0d7858ae10aad25a5)
* Refactor the build process [1/2]. [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/e0cb91d0284034ccb503907ba1bf331edc234bb0)
* Add the "Unix" Completion functions. [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/57bb7730e5b763c0c1a19490ca024b07b20e9c09)
* Fix user reporting on some custom roms. [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/d4b1366402da36141d29966b6096b6b5ebd728c2)
* Fix the module description drawing function. [view commit](http://github.com/partcyborg/zsh_arm64_magisk/commit/58153ecdc9c4c0e30bc466993104f57d8c24cdd4)

v1.0 - 4/20/2019
* Initial Release.
