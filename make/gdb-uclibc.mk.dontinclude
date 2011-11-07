############################################################
#
# build gdb for use on the host system
#
############################################################
GDB_SITE:=http://ftp.gnu.org/gnu/gdb
GDB_SOURCE:=gdb-6.0.tar.bz2
GDB_DIR:=$(TOOL_BUILD_DIR)/gdb-6.0
GDB_CAT:=bzcat

GDB_BUILD_DIR1:=$(TOOL_BUILD_DIR)/gdb-build

$(DL_DIR)/$(GDB_SOURCE):
	$(WGET) -P $(DL_DIR) $(GDB_SITE)/$(GDB_SOURCE)

$(GDB_DIR)/.unpacked: $(DL_DIR)/$(GDB_SOURCE)
	mkdir -p $(TOOL_BUILD_DIR)
	mkdir -p $(DL_DIR)
	$(GDB_CAT) $(DL_DIR)/$(GDB_SOURCE) | tar -C $(TOOL_BUILD_DIR) -xvf -
	touch $(GDB_DIR)/.unpacked

#
# Apply any files named gdb-*.patch from the sources/ directory
#
$(GDB_DIR)/.patched: $(GDB_DIR)/.unpacked
	$(SOURCE_DIR)/patch-kernel.sh $(GDB_DIR) $(SOURCE_DIR) gdb-*.patch
	touch $(GDB_DIR)/.patched

$(GDB_BUILD_DIR1)/.configured: $(GDB_DIR)/.patched
	mkdir -p $(GDB_BUILD_DIR1)
	(cd $(GDB_BUILD_DIR1); PATH=$(TARGET_PATH) \
		$(GDB_DIR)/configure \
		--prefix=$(STAGING_DIR) \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_HOST_NAME) \
		--target=$(REAL_GNU_TARGET_NAME) \
		$(DISABLE_NLS) \
		$(MULTILIB) \
		$(SOFT_FLOAT_CONFIG_OPTION) );
	touch $(GDB_BUILD_DIR1)/.configured

$(GDB_BUILD_DIR1)/.compiled: $(GDB_BUILD_DIR1)/.configured
	PATH=$(TARGET_PATH) $(MAKE) $(JLEVEL) -C $(GDB_BUILD_DIR1) all
	touch $(GDB_BUILD_DIR1)/.compiled

$(GDB_BUILD_DIR1)/.installed: $(GDB_BUILD_DIR1)/.compiled
	PATH=$(TARGET_PATH) $(MAKE) $(JLEVEL) -C $(GDB_BUILD_DIR1) install
	touch $(GDB_BUILD_DIR1)/.installed

gdb: $(GDB_BUILD_DIR1)/.installed

gdb-source: $(DL_DIR)/$(GDB_SOURCE)

gdb-clean:
	rm -f $(STAGING_DIR)/bin/$(REAL_GNU_TARGET_NAME)*
	-$(MAKE) -C $(GDB_BUILD_DIR1) clean

gdb-dirclean:
	rm -rf $(GDB_BUILD_DIR1)


#############################################################
#
# build gdb for use on the target system (includes gdbserver)
#
#############################################################
GDB_BUILD_DIR2:=$(TOOL_BUILD_DIR)/gdb-target

#
# FIXME
# This could do with a cleanup:
#   - multilib, nls, etc. stuff. not sure gdb recognises these.
#   - crosscheck target install.
#   - fix gdbserver target. fixup CFLAGS to build a static binary.
#     useful if .so's don't exist, or are broken. strip resultant binary.
#
$(GDB_BUILD_DIR2)/.configured: $(GDB_DIR)/.patched
	mkdir -p $(GDB_BUILD_DIR2)
	(cd $(GDB_BUILD_DIR2); \
		PATH=$(TARGET_PATH) \
		CFLAGS="$(TARGET_CFLAGS)" \
		$(GDB_DIR)/configure \
		--prefix=/usr \
		--exec-prefix=/usr \
		--build=$(GNU_HOST_NAME) \
		--host=$(REAL_GNU_TARGET_NAME) \
		--target=$(REAL_GNU_TARGET_NAME) \
		$(DISABLE_NLS) \
		$(MULTILIB) \
		$(SOFT_FLOAT_CONFIG_OPTION) );
	touch $(GDB_BUILD_DIR2)/.configured

$(GDB_BUILD_DIR2)/.compiled: $(GDB_BUILD_DIR2)/.configured
	PATH=$(TARGET_PATH) $(MAKE) $(JLEVEL) -C $(GDB_BUILD_DIR2) all
	touch $(GDB_BUILD_DIR2)/.compiled

$(GDB_BUILD_DIR2)/.installed: $(GDB_BUILD_DIR2)/.compiled
	PATH=$(TARGET_PATH) \
	$(MAKE) $(JLEVEL) DESTDIR=$(TARGET_DIR) \
		tooldir=/usr build_tooldir=/usr \
		-C $(GDB_BUILD_DIR2) install
	-$(STRIP) $(TARGET_DIR)/usr/$(REAL_GNU_TARGET_NAME)/bin/* > /dev/null 2>&1
	-$(STRIP) $(TARGET_DIR)/usr/bin/* > /dev/null 2>&1

gdb_target: $(GDB_BUILD_DIR2)/.installed

gdbserver:

gdb_target-clean:
	rm -f $(TARGET_DIR)/bin/$(REAL_GNU_TARGET_NAME)*
	-$(MAKE) -C $(GDB_BUILD_DIR2) clean

gdb_target-dirclean:
	rm -rf $(GDB_BUILD_DIR2)

