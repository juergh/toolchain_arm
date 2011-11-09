ZLIB_SITE := http://zlib.net/fossils/
ZLIB_SOURCE := zlib-1.2.3.tar.gz

ZLIB_DIR := $(TOOL_BUILD_DIR)/zlib-1.2.3

$(DL_DIR)/$(ZLIB_SOURCE):
	$(WGET) -P $(DL_DIR) $(ZLIB_SITE)/$(ZLIB_SOURCE)

$(ZLIB_DIR)/.unpacked: $(DL_DIR)/$(ZLIB_SOURCE)
	mkdir -p $(TOOL_BUILD_DIR)
	mkdir -p $(DL_DIR)
	tar -C $(TOOL_BUILD_DIR) -xzvf $(DL_DIR)/$(ZLIB_SOURCE)
	touch $(ZLIB_DIR)/.unpacked

$(ZLIB_DIR)/.configured: $(ZLIB_DIR)/.unpacked
	( cd $(ZLIB_DIR); \
		PATH=$(TARGET_PATH) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CC=$(TARGET_CC) \
		$(ZLIB_DIR)/configure \
		--prefix=$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME) \
		--exec-prefix=$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME) \
		--shared );
	touch $(ZLIB_DIR)/.configured

$(ZLIB_DIR)/libz.so: $(ZLIB_DIR)/.configured
	$(MAKE) -C $(ZLIB_DIR)

$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/lib/libz.so: $(ZLIB_DIR)/libz.so
	$(MAKE) -C $(ZLIB_DIR) install

zlib: $(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/lib/libz.so

zlib-source: $(DL_DIR)/$(ZLIB_SOURCE)

zlib-clean:
	-$(MAKE) -C $(ZLIB_DIR) clean

zlib-dirclean:
	rm -rf $(ZLIB_DIR1)
