include $(TOPDIR)/rules.mk

PKG_NAME:=glinet-panel-firmware
PKG_RELEASE:=1

PKG_MAINTAINER:=John Crispin <john@phrozen.org>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/glinet-panel-firmware
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=GL.iNet ST7789P3 panel init firmware
  DEPENDS:=@TARGET_mediatek_filogic
endef

define Package/glinet-panel-firmware/description
  panel-mipi-dbi init command sequences for the Sitronix ST7789P3 LCD that the
  GL.iNet BE10000 and BE14000 carry. Both boards use the same panel and the
  same sequence, but mounted 180 degrees apart, so the two blobs differ in the
  MADCTL byte alone. panel-mipi-dbi names the firmware after the first
  compatible string of the panel node, so each board gets its own name. See
  gen-panel-fw.py for how the blobs are built.
endef

define Build/Compile
endef

define Package/glinet-panel-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DATA) ./files/gl-panel.bin \
		$(1)/lib/firmware/glinet,st7789p3-panel.bin
	$(INSTALL_DATA) ./files/gl-be14000-panel.bin \
		$(1)/lib/firmware/glinet,gl-be14000-panel.bin
endef

$(eval $(call BuildPackage,glinet-panel-firmware))
