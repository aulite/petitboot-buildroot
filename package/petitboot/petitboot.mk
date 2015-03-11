################################################################################
#
# petitboot
#
################################################################################

PETITBOOT_VERSION = e330e3f5adf78d3ba77217995a4bc3cd1fd16f4c
PETITBOOT_SITE = git://ozlabs.org/~jk/petitboot
PETITBOOT_DEPENDENCIES = ncurses udev host-bison host-flex host-localedef
PETITBOOT_LICENSE = GPLv2
PETITBOOT_LICENSE_FILES = COPYING

PETITBOOT_AUTORECONF = YES
PETITBOOT_AUTORECONF_OPTS = -i
PETITBOOT_GETTEXTIZE = YES
PETITBOOT_CONF_OPTS += --with-ncurses --without-twin-x11 --without-twin-fbdev \
	      --localstatedir=/var \
	      HOST_PROG_KEXEC=/usr/sbin/kexec \
	      HOST_PROG_SHUTDOWN=/usr/libexec/petitboot/bb-kexec-reboot \
	      $(if $(BR2_PACKAGE_BUSYBOX),--with-tftp=busybox)

ifdef PETITBOOT_DEBUG
PETITBOOT_CONF_OPTS += --enable-debug
endif

ifeq ($(BR2_PACKAGE_NCURSES_WCHAR),y)
PETITBOOT_CONF_OPTS += --with-ncursesw MENU_LIB=-lmenuw FORM_LIB=-lformw
endif

PETITBOOT_PRE_CONFIGURE_HOOKS += PETITBOOT_PRE_CONFIGURE_BOOTSTRAP

define PETITBOOT_POST_INSTALL
	$(INSTALL) -D -m 0755 $(@D)/utils/bb-kexec-reboot \
		$(TARGET_DIR)/usr/libexec/petitboot
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/petitboot/boot.d
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/01-create-default-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/20-set-stdout \
		$(TARGET_DIR)/etc/petitboot/boot.d/

	$(INSTALL) -D -m 0755 package/petitboot/S14silence-console \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 package/petitboot/S15pb-discover \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 package/petitboot/kexec-restart \
		$(TARGET_DIR)/usr/sbin/
	$(INSTALL) -D -m 0755 package/petitboot/petitboot-console-ui.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	$(SED) 's/GENERIC_GETTY_PORT/$(call qstrip,$(BR2_TARGET_GENERIC_GETTY_PORT))/' \
		$(TARGET_DIR)/etc/udev/rules.d/petitboot-console-ui.rules

	$(INSTALL) -D -m 0755 package/petitboot/removable-event-poll.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	ln -sf /usr/sbin/pb-udhcpc \
		$(TARGET_DIR)/usr/share/udhcpc/default.script.d/
endef

PETITBOOT_POST_INSTALL_TARGET_HOOKS += PETITBOOT_POST_INSTALL

$(eval $(autotools-package))
