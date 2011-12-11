LIBUSB_SITE := http://downloads.sourceforge.net/project/libusb/libusb-0.1%20%28LEGACY%29/0.1.12
LIBUSB_SOURCE := libusb-0.1.12.tar.gz

LIBUSB_DIR := $(TOOL_BUILD_DIR)/libusb-0.1.12

$(DL_DIR)/$(LIBUSB_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBUSB_SITE)/$(LIBUSB_SOURCE)

$(LIBUSB_DIR)/.unpacked: $(DL_DIR)/$(LIBUSB_SOURCE)
	mkdir -p $(TOOL_BUILD_DIR)
	mkdir -p $(DL_DIR)
	tar -C $(TOOL_BUILD_DIR) -xzvf $(DL_DIR)/$(LIBUSB_SOURCE)
	touch $(LIBUSB_DIR)/.unpacked

$(LIBUSB_DIR)/.patched: $(LIBUSB_DIR)/.unpacked
	# Apply any files named libusb-*.patch from the source directory
	$(SOURCE_DIR)/patch-kernel.sh $(LIBUSB_DIR) $(SOURCE_DIR) libusb*.patch
	touch $(LIBUSB_DIR)/.patched

$(LIBUSB_DIR)/.configured: $(LIBUSB_DIR)/.patched $(LIBUSB_DIR)/.unpacked
	( cd $(LIBUSB_DIR); \
		PATH=$(TARGET_PATH) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CC=$(TARGET_CC) \
		$(LIBUSB_DIR)/configure \
		--prefix=$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME) \
		--exec-prefix=$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME) \
		--host=i686-pc-linux-gnu \
		--disable-static );
	touch $(LIBUSB_DIR)/.configured

$(LIBUSB_DIR)/.libs/libusb.so: $(LIBUSB_DIR)/.configured
	$(MAKE) -C $(LIBUSB_DIR)

$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/lib/libusb.so: $(LIBUSB_DIR)/.libs/libusb.so
	$(MAKE) -C $(LIBUSB_DIR) install

libusb: $(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/lib/libusb.so

libusb-source: $(DL_DIR)/$(LIBUSB_SOURCE)

libusb-clean:
	-$(MAKE) -C $(LIBUSB_DIR) clean

libusb-dirclean:
	rm -rf $(LIBUSB_DIR)
