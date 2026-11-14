#!/system/bin/sh
# Sourced (not executed) by the Magisk / KernelSU module installer after the
# zip has been extracted into $MODPATH and default permissions applied.
# See: https://topjohnwu.github.io/Magisk/guides/module.html

if [ "$ARCH" != "arm64" ]; then
  abort "! This module only supports arm64 (aarch64) devices"
fi

ui_print "- Installing Zsh for Arm64"

# KernelSU leaves every extracted file at 0644, and Magisk only auto-executes
# a few well known bin directories.  Set everything explicitly so the zsh
# binary and shell startup files behave the same under both managers.
set_perm_recursive $MODPATH/system 0 0 0755 0644
set_perm_recursive $MODPATH/system/xbin 0 2000 0755 0755
