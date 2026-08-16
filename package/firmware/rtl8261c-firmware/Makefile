include $(TOPDIR)/rules.mk

PKG_NAME:=rtl8261c-firmware
PKG_RELEASE:=1

PKG_MAINTAINER:=John Crispin <john@phrozen.org>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/rtl8261c-firmware
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=Realtek RTL8261C/D-CG 10Gbps PHY firmware
endef

define Package/rtl8261c-firmware/description
  Firmware patch blob for the Realtek RTL8261C/D-CG 10Gbps copper PHY,
  loaded by the realtek PHY driver via request_firmware(rtl8261c.bin)
  during patch-mode init.
endef

define Build/Compile
endef

define Package/rtl8261c-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) ./files/rtl8261c.bin \
		$(1)/lib/firmware/rtl8261c.bin
endef

$(eval $(call BuildPackage,rtl8261c-firmware))
