LIBID3TAG_SITE := http://downloads.sourceforge.net/project/mad/libid3tag/0.15.1b
LIBID3TAG_SOURCE := libid3tag-0.15.1b.tar.gz

LIBID3TAG_DIR := $(TOOL_BUILD_DIR)/libid3tag-0.15.1b

$(DL_DIR)/$(LIBID3TAG_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBID3TAG_SITE)/$(LIBID3TAG_SOURCE)

$(LIBID3TAG_DIR)/.unpacked: $(DL_DIR)/$(LIBID3TAG_SOURCE)
	mkdir -p $(TOOL_BUILD_DIR)
	mkdir -p $(DL_DIR)
	tar -C $(TOOL_BUILD_DIR) -xzvf $(DL_DIR)/$(LIBID3TAG_SOURCE)
	touch $(LIBID3TAG_DIR)/.unpacked

$(LIBID3TAG_DIR)/.configured: $(LIBID3TAG_DIR)/.unpacked
	( cd $(LIBID3TAG_DIR); \
		PATH=$(TARGET_PATH) \
		CFLAGS="$(TARGET_CFLAGS)" \
		CC=$(TARGET_CC) \
		$(LIBID3TAG_DIR)/configure \
		--prefix=$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME) \
		--exec-prefix=$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME) \
		--host=i686-pc-linux-gnu \
		--disable-static );
	touch $(LIBID3TAG_DIR)/.configured

$(LIBID3TAG_DIR)/.libs/libid3tag.so: $(LIBID3TAG_DIR)/.configured
	$(MAKE) -C $(LIBID3TAG_DIR)

$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/lib/libid3tag.so: $(LIBID3TAG_DIR)/.libs/libid3tag.so
	$(MAKE) -C $(LIBID3TAG_DIR) install

libid3tag: $(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/lib/libid3tag.so

libid3tag-source: $(DL_DIR)/$(LIBID3TAG_SOURCE)

libid3tag-clean:
	-$(MAKE) -C $(LIBID3TAG_DIR) clean

libid3tag-dirclean:
	rm -rf $(LIBID3TAG_DIR)
