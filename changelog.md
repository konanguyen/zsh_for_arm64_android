### Changelog

#### v1.5 - 11/15/2026
* Update zsh to 5.9 and link it against a statically built ncurses 6.5 (built-in terminfo fallbacks, no terminfo database required on device).
* Build with the Android NDK (bionic) instead of a static glibc cross toolchain.
* Modernize the module layout for current Magisk (>= v20.4) and KernelSU: `customize.sh` replaces the legacy `install.sh`/`common/` scripts, and `META-INF/com/google/android/update-binary` is the official installer stub.
* Add LICENSE (the zsh licence) and a CI workflow that builds releases on tag push.

#### v1.2 - 8/07/2019
* Update README.
* Move the README file to the project root.

#### v1.1 - 8/05/2019
* Minor bugfixes and cleanups.
* Refactor the build process.
* Add the "Unix" Completion functions.
* Fix user reporting on some custom roms.
* Fix the module description drawing function.

#### v1.0 - 4/20/2019
* Initial Release.
