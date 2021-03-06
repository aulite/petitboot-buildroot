################################################################################
#
# petitboot
#
################################################################################

PETITBOOT_VERSION = v1.3.1
PETITBOOT_SITE = git://ozlabs.org/petitboot
PETITBOOT_DEPENDENCIES = ncurses udev host-bison host-flex lvm2
PETITBOOT_LICENSE = GPLv2
PETITBOOT_LICENSE_FILES = COPYING

PETITBOOT_GETTEXTIZE = YES
PETITBOOT_AUTORECONF = YES

PETITBOOT_CONF_OPTS += \
	PACKAGE_VERSION=$(PETITBOOT_VERSION) \
	HOST_PROG_KEXEC=/usr/sbin/kexec \
	HOST_PROG_SHUTDOWN=/usr/libexec/petitboot/bb-kexec-reboot \
	--with-ncurses \
	--without-twin-x11 \
	--without-twin-fbdev \
	--localstatedir=/var \
	$(if $(BR2_PACKAGE_BUSYBOX),--with-tftp=busybox)

ifdef PETITBOOT_DEBUG
PETITBOOT_CONF_OPTS += --enable-debug
endif

ifeq ($(BR2_PACKAGE_NCURSES_WCHAR),y)
PETITBOOT_CONF_OPTS += \
	--with-ncursesw \
	MENU_LIB=-lmenuw \
	FORM_LIB=-lformw
endif

define PETITBOOT_POST_INSTALL
	$(INSTALL) -D -m 0755 $(@D)/utils/bb-kexec-reboot \
		$(TARGET_DIR)/usr/libexec/petitboot
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/petitboot/boot.d
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/01-create-default-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/01-create-default-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/30-dtb_updates \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/90-sort-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/

	$(INSTALL) -D -m 0755 package/petitboot/files/S14silence-console \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 package/petitboot/files/S15pb-discover \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 package/petitboot/files/kexec-restart \
		$(TARGET_DIR)/usr/sbin/
	$(INSTALL) -D -m 0755 package/petitboot/files/petitboot-console-ui.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	$(SED) 's/GENERIC_GETTY_PORT/$(call qstrip,$(BR2_TARGET_GENERIC_GETTY_PORT))/' \
		$(TARGET_DIR)/etc/udev/rules.d/petitboot-console-ui.rules

	$(INSTALL) -D -m 0755 package/petitboot/files/removable-event-poll.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	$(INSTALL) -D -m 0755 package/petitboot/files/63-md-raid-arrays.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 package/petitboot/files/65-md-incremental.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	ln -sf /usr/sbin/pb-udhcpc \
		$(TARGET_DIR)/usr/share/udhcpc/default.script.d/

	mkdir -p $(TARGET_DIR)/var/log/petitboot

	$(MAKE) -C $(@D)/po DESTDIR=$(TARGET_DIR) install
endef

PETITBOOT_POST_INSTALL_TARGET_HOOKS += PETITBOOT_POST_INSTALL

$(eval $(autotools-package))
