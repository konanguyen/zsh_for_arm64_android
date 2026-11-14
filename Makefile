MODVERSION := $(shell sed -n 's/version=\(.*\)/\1/p' module.prop)
MOD := zsh_arm64
ZIP := $(MOD)-$(MODVERSION).zip
#ZIP := $(MOD)-$(MODVERSION)-$(shell date +%m-%d).zip

VCODE := $(subst .,,$(MODVERSION))

# Trigger a rebuild when any tracked project file changes.  git ls-files
# keeps untracked build outputs (e.g. an NDK extracted inside the tree on
# CI) out of the dependency list, which a plain `find .` would pick up.
DEPS := $(shell git ls-files)

# Modern Magisk (>= v20.4) installer layout: module.prop, customize.sh,
# system/, META-INF.  install.sh and common/ must NOT ship (see Magisk
# docs/guides.md); customize.sh replaces the old install.sh callbacks.
MODFILES := META-INF customize.sh system module.prop README.md

ZSHVERSION := 5.9
SRCDIR=zsh-$(ZSHVERSION)
SRCURL := https://sourceforge.net/projects/zsh/files/zsh/$(ZSHVERSION)/zsh-$(ZSHVERSION).tar.xz/download
ARCHIVE := $(SRCDIR).tar.xz

# ncurses is built only for its static libncurses (termcap/tinfo interface
# used by zle).  Fallback terminfo entries are compiled into the library so
# no terminfo database is needed on the device; the compiled-in search path
# additionally matches the one Android itself ships (/system/etc/terminfo).
NCURSESVERSION := 6.5
NCSRCDIR=ncurses-$(NCURSESVERSION)
NCSRCURL := https://ftp.gnu.org/gnu/ncurses/ncurses-$(NCURSESVERSION).tar.gz
NCARCHIVE := $(NCSRCDIR).tar.gz
# NOTE: names must be distinct non-alias entries in misc/terminfo.src;
# alias names (e.g. rxvt-color) produce duplicate symbols in fallback.c.
NCFALLBACK := ansi,dumb,linux,vt52,vt100,vt102,vt220,vt320,vt420,xterm,xterm-color,xterm-16color,xterm-88color,xterm-256color,rxvt,screen,screen-256color,tmux,tmux-256color,putty,putty-256color,gnome,gnome-256color,konsole,konsole-256color,Eterm,eterm-color,alacritty,foot

# Android NDK toolchain (clang/lld).  Bionic has no static libc, so the
# binary links dynamically against the system libc instead.  API 24
# (Android 7.0) matches the minimum Android version Magisk supports.
NDK ?= $(HOME)/Android/Sdk/ndk/29.0.14206865
TC := $(NDK)/toolchains/llvm/prebuilt/linux-x86_64/bin
CROSS := aarch64-linux-android24
NDKCFLAGS := -O2 -fPIE -Wno-error=implicit-function-declaration -Wno-error=int-conversion

CURDIR := $(shell pwd)
PROCS := $(shell nproc)
WORK := $(CURDIR)/build/work
DEPSTAGE := $(WORK)/android-deps
NCOBJ := $(WORK)/$(NCSRCDIR)/obj
NCOBJNATIVE := $(WORK)/$(NCSRCDIR)/obj-native
NCTIC := $(NCOBJNATIVE)/progs/tic

.PHONY: all clean distclean

all: out/$(ZIP)

build/work/$(ARCHIVE):
	mkdir -p $(WORK); \
	wget --output-document=$(WORK)/$(ARCHIVE) $(SRCURL); \
	cd $(WORK); tar xf $(ARCHIVE)

build/work/$(NCARCHIVE):
	mkdir -p $(WORK); \
	wget --output-document=$(WORK)/$(NCARCHIVE) $(NCSRCURL); \
	cd $(WORK); tar xf $(NCARCHIVE)

# Host-native tic/infocmp are required to compile the fallback terminfo
# entries into the cross-built library (MKfallback.sh runs them at build
# time); configure empties FALLBACK_LIST without them.
$(NCTIC): build/work/$(NCARCHIVE)
	mkdir -p $(NCOBJNATIVE); \
	cd $(NCOBJNATIVE); \
	../configure \
		--prefix=$(DEPSTAGE)/native \
		--without-shared \
		--without-debug \
		--without-ada \
		--without-cxx \
		--without-cxx-binding \
		--without-gpm \
		--without-manpages \
		--without-tack \
		--disable-db-install >/dev/null; \
	$(MAKE) -j$(PROCS)

$(DEPSTAGE)/lib/libncurses.a: $(NCTIC)
	mkdir -p $(NCOBJ); \
	cd $(NCOBJ); \
	../configure \
		--host=$(CROSS) \
		--prefix=$(DEPSTAGE) \
		--with-fallbacks="$(NCFALLBACK)" \
		--with-tic-path=$(NCTIC) \
		--with-infocmp-path=$(NCOBJNATIVE)/progs/infocmp \
		--with-terminfo-dirs=/system/etc/terminfo:/system/usr/share/terminfo \
		--disable-db-install \
		--disable-widec \
		--without-progs \
		--without-tack \
		--without-ada \
		--without-cxx \
		--without-cxx-binding \
		--without-debug \
		--without-gpm \
		--without-manpages \
		--without-profile \
		--without-shared \
		--with-normal \
		--with-build-cc=gcc \
		CC=$(TC)/$(CROSS)-clang \
		LD=$(TC)/$(CROSS)-clang \
		AR=$(TC)/llvm-ar \
		RANLIB=$(TC)/llvm-ranlib \
		STRIP=$(TC)/llvm-strip \
		CFLAGS="$(NDKCFLAGS)"; \
	grep -q "^FALLBACK_LIST	= ." $(NCOBJ)/ncurses/Makefile || \
		{ echo "ERROR: ncurses fallback list is empty; tic/infocmp missing"; exit 1; }; \
	$(MAKE) -C $(NCOBJ) -j$(PROCS) libs; \
	$(MAKE) -C $(NCOBJ) install

build/work/$(SRCDIR)/Makefile: build/work/$(ARCHIVE) $(DEPSTAGE)/lib/libncurses.a $(CURDIR)/build/config.modules
	cd $(WORK)/$(SRCDIR); \
	cp $(CURDIR)/build/config.modules .; \
	CFLAGS="$(NDKCFLAGS)" \
	CPPFLAGS="-I$(DEPSTAGE)/include -I$(DEPSTAGE)/include/ncurses" \
	LDFLAGS="-L$(DEPSTAGE)/lib" \
	CC=$(TC)/$(CROSS)-clang \
	AR=$(TC)/llvm-ar \
	RANLIB=$(TC)/llvm-ranlib \
	STRIP=$(TC)/llvm-strip \
	./configure \
		--bindir=/system/xbin \
		--datarootdir=/system/usr/share \
		--disable-dynamic \
		--disable-dynamic-nss \
		--disable-gdbm \
		--disable-restricted-r \
		--disable-runhelpdir \
		--enable-zshenv=/system/etc/zsh/zshenv \
		--enable-zprofile=/system/etc/zsh/zprofile \
		--enable-zlogin=/system/etc/zsh/zlogin \
		--enable-zlogout=/system/etc/zsh/zlogout \
		--enable-multibyte \
		--enable-site-fndir=/system/usr/share/zsh/functions \
		--enable-fndir=/system/usr/share/zsh/functions \
		--enable-function-subdirs \
		--enable-scriptdir=/system/usr/share/zsh/scripts \
		--enable-site-scriptdir=/system/usr/share/zsh/scripts \
		--enable-etcdir=/system/etc \
		--enable-libs=-lncurses \
		--host=$(CROSS) \
		--libexecdir=/system/xbin \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sysconfdir=/system/etc

build/work/$(SRCDIR)/Src/zsh: build/work/$(SRCDIR)/Makefile $(DEPS)
	cd $(WORK)/$(SRCDIR); \
	make -j$(PROCS)

$(CURDIR)/system/xbin/zsh: build/work/$(SRCDIR)/Src/zsh
	cd $(WORK)/$(SRCDIR); \
	make install DESTDIR=$(CURDIR); \
	chmod 755 $(CURDIR)/system/xbin/*

out/$(ZIP): $(DEPS) $(CURDIR)/system/xbin/zsh
	mkdir -p out; \
	cd $(CURDIR); \
		rm -rf system/usr/share/man; \
		rm -f system/xbin/zsh-* system/xbin/zsh.old; \
		zip -qr out/$(ZIP) $(MODFILES)

clean:
	rm -rf build/work/*

distclean: clean
	rm -f out/*.zip
