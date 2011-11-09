# Makefile for to build gcc for uClibc
#
# Copyright (C) 2002-2004 Erik Andersen <andersen@uclibc.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

#############################################################
#
# EDIT this stuff to suit your system and preferences
#
# Use := when possible to get precomputation, thereby
# speeding up the build process.
#
#############################################################


# What sortof target system shall we compile this for?
#ARCH:=i386
ARCH:=arm
#ARCH:=mips
#ARCH:=mipsel
#ARCH:=powerpc
#ARCH:=sh4
#ARCH:=cris
#ARCH:=sh64
#ARCH:=m68k
#ARCH:=v850
#ARCH:=sparc
#ARCH:=whatever

# Enable this to use the uClibc daily snapshot instead of a released
# version.  Daily snapshots may contain new features and bugfixes. Or
# they may not even compile at all, depending on what Erik is doing...
USE_UCLIBC_SNAPSHOT:=false

# Enable large file (files > 2 GB) support
BUILD_WITH_LARGEFILE:=true

# Command used to download source code
WGET:=wget --passive-ftp

# Optimize toolchain for which type of CPU?
OPTIMIZE_FOR_CPU=$(ARCH)
#OPTIMIZE_FOR_CPU=i686
#OPTIMIZE_FOR_CPU=i586
#OPTIMIZE_FOR_CPU=whatever

# Soft floating point options.
# Notes:
#   Currently builds with gcc 3.3 for arm, mips, mipsel, powerpc.
#   (i386 support will be added back in at some point.)
#   Only tested with multilib enabled.
#   For i386, long double is the same as double (64 bits).  While this
#      is unusual for x86, it seemed the best approach considering the
#      limitations in the gcc floating point emulation library.
#   For arm, soft float uses the usual libfloat routines.
#   Custom specs files are used to set the default gcc mode to soft float
#      as a convenience, since you shouldn't link hard and soft float
#      together.  In fact, arm won't even let you.
# (Un)comment the appropriate line below.
SOFT_FLOAT:=false

TARGET_OPTIMIZATION=-Os
TARGET_DEBUGGING= #-g

# Currently the unwind stuff seems to work for staticly linked apps but
# not dynamic.  So use setjmp/longjmp exceptions by default.
GCC_USE_SJLJ_EXCEPTIONS:=--enable-sjlj-exceptions
#GCC_USE_SJLJ_EXCEPTIONS:=

# Any additional gcc options you may want to include....
EXTRA_GCC_CONFIG_OPTIONS:=

# Enable the following if you want locale/gettext/i18n support.
# NOTE!  Currently the pregnerated locale stuff only works for x86!
ENABLE_LOCALE:=false
#ENABLE_LOCAL:=true

# If you want multilib enabled, enable this...
MULTILIB:=--enable-multilib

# Build/install c++ compiler and libstdc++?
INSTALL_LIBSTDCPP:=true

# Build/install java compiler and libgcj? (requires c++)
# WARNING!!! DOES NOT BUILD FOR TARGET WITHOUT INTERVENTION!!!  mjn3
#INSTALL_LIBGCJ:=true
INSTALL_LIBGCJ:=false

# For SMP machines some stuff can be run in parallel
#JLEVEL=-j3


#############################################################
#
# You should probably leave this stuff alone unless you know
# what you are doing.
#
#############################################################
TARGETS+=host-sed kernel-headers uclibc-configured binutils \
	 gcc3_3 post_fixups  #gdb #ccache

#############################################################
#
# You should probably leave this stuff alone unless you know
# what you are doing.
#
#############################################################

ifeq ($(SOFT_FLOAT),true)
SOFT_FLOAT_CONFIG_OPTION:=--without-float
TARGET_SOFT_FLOAT:=-msoft-float
ARCH_FPU_SUFFIX:=_nofpu
else
SOFT_FLOAT_CONFIG_OPTION:=
TARGET_SOFT_FLOAT:=
ARCH_FPU_SUFFIX:=
endif

ifeq ($(INSTALL_LIBGCJ),true)
INSTALL_LIBSTDCPP:=true
endif

# WARNING -- uClibc currently disables large file support on cris.
ifeq ("$(strip $(ARCH))","cris")
BUILD_WITH_LARGEFILE:=false
endif

ifneq ($(BUILD_WITH_LARGEFILE),true)
DISABLE_LARGEFILE= --disable-largefile
endif
TARGET_CFLAGS=$(TARGET_OPTIMIZATION) $(TARGET_DEBUGGING)

HOSTCC:=gcc
BASE_DIR:=$(shell pwd)
SOURCE_DIR:=$(BASE_DIR)/sources
DL_DIR:=$(SOURCE_DIR)/dl
PATCH_DIR=$(SOURCE_DIR)/patches
BUILD_DIR=$(BASE_DIR)/toolchain_$(ARCH)$(ARCH_FPU_SUFFIX)
STAGING_DIR=$(BUILD_DIR)
TOOL_BUILD_DIR=$(BASE_DIR)/toolchain_build_$(ARCH)$(ARCH_FPU_SUFFIX)
TARGET_PATH=$(STAGING_DIR)/bin:/bin:/sbin:/usr/bin:/usr/sbin
REAL_GNU_TARGET_NAME=$(OPTIMIZE_FOR_CPU)-linux-uclibc
GNU_TARGET_NAME=$(OPTIMIZE_FOR_CPU)-linux
KERNEL_CROSS=$(STAGING_DIR)/bin/$(OPTIMIZE_FOR_CPU)-linux-uclibc-
TARGET_CROSS=$(STAGING_DIR)/bin/$(OPTIMIZE_FOR_CPU)-linux-uclibc-
TARGET_CC=$(TARGET_CROSS)gcc
STRIP=$(TARGET_CROSS)strip --remove-section=.comment --remove-section=.note


HOST_ARCH:=$(shell $(HOSTCC) -dumpmachine | sed -e s'/-.*//' \
	-e 's/sparc.*/sparc/' \
	-e 's/arm.*/arm/g' \
	-e 's/m68k.*/m68k/' \
	-e 's/ppc/powerpc/g' \
	-e 's/v850.*/v850/g' \
	-e 's/sh[234]/sh/' \
	-e 's/mips-.*/mips/' \
	-e 's/mipsel-.*/mipsel/' \
	-e 's/cris.*/cris/' \
	-e 's/i[3-9]86/i386/' \
	)
GNU_HOST_NAME:=$(HOST_ARCH)-pc-linux-gnu
TARGET_CONFIGURE_OPTS=PATH=$(TARGET_PATH) \
		AR=$(TARGET_CROSS)ar \
		AS=$(TARGET_CROSS)as \
		LD=$(TARGET_CROSS)ld \
		NM=$(TARGET_CROSS)nm \
		CC=$(TARGET_CROSS)gcc \
		GCC=$(TARGET_CROSS)gcc \
		CXX=$(TARGET_CROSS)g++ \
		RANLIB=$(TARGET_CROSS)ranlib

ifeq ($(ENABLE_LOCALE),true)
DISABLE_NLS:=
else
DISABLE_NLS:=--disable-nls
endif


all:   world

TARGETS_CLEAN:=$(patsubst %,%-clean,$(TARGETS))
TARGETS_SOURCE:=$(patsubst %,%-source,$(TARGETS))
TARGETS_DIRCLEAN:=$(patsubst %,%-dirclean,$(TARGETS))

world: $(DL_DIR) $(STAGING_DIR) $(TARGETS)

.PHONY: all world clean dirclean distclean source $(TARGETS) \
	$(TARGETS_CLEAN) $(TARGETS_DIRCLEAN) $(TARGETS_SOURCE)

include make/*.mk

$(BUILD_DIR)/build-env:
	@cp sources/build-env $(BUILD_DIR)

$(BUILD_DIR)/$(OPTIMIZE_FOR_CPU)-linux-uclibc/lib/ldscripts:
	@cd $(BUILD_DIR)/$(OPTIMIZE_FOR_CPU)-linux-uclibc/lib && \
		ln -sf ../../lib/ldscripts

post_fixups: $(BUILD_DIR)/build-env \
	$(BUILD_DIR)/$(OPTIMIZE_FOR_CPU)-linux-uclibc/lib/ldscripts

#############################################################
#
# staging and target directories do NOT list these as
# dependancies anywhere else
#
#############################################################
$(DL_DIR):
	mkdir $(DL_DIR)

$(STAGING_DIR):
	rm -rf $(STAGING_DIR)
	mkdir -p $(BUILD_DIR)
	mkdir -p $(TOOL_BUILD_DIR)
	mkdir -p $(STAGING_DIR)/lib
	mkdir -p $(STAGING_DIR)/usr
	mkdir -p $(STAGING_DIR)/include
	ln -fs ../lib $(STAGING_DIR)/usr/lib

source: $(TARGETS_SOURCE)

#############################################################
#
# Cleanup and misc junk
#
#############################################################
clean: $(TARGETS_CLEAN)
	rm -rf $(STAGING_DIR)
	rm -rf $(TOOL_BUILD_DIR)
	rm -rf $(DL_DIR)
	@find . \( -name '*~' \) -type f -print | xargs rm -f

dirclean: $(TARGETS_DIRCLEAN)
	rm -rf $(STAGING_DIR)

distclean:
	rm -rf $(DL_DIR) $(BUILD_DIR) $(TOOL_BUILD_DIR) $(LINUX_KERNEL)

sourceball:
	rm -rf $(BUILD_DIR)
	set -e; \
	cd ..; \
	rm -f toolchain.tar.bz2; \
	tar -cvf toolchain.tar toolchain; \
	bzip2 -9 toolchain.tar; \


