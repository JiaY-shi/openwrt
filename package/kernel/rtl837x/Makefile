include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=rtl837x-dsa
PKG_VERSION:=0.1.0
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/airjinkela/rtl837x-dsa-driver.git
PKG_SOURCE_DATE:=2026-09-21
PKG_SOURCE_VERSION:=b14546dbeabf500c287a6ff7ce847919a02d4a26
PKG_MIRROR_HASH:=32217f232af4b5652a4a516f2f7fd944570f583078d5b23ee12b92801f36cc8e

PKG_MAINTAINER:=StarField Xu <air_jinkela@163.com>
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_BUILD_PARALLEL:=1
PKG_EXTMOD_SUBDIRS:=src

include $(INCLUDE_DIR)/package.mk

define KernelPackage/$(PKG_NAME)
  SUBMENU:=Other modules
  TITLE:=Realtek RTL8372N DSA switch driver
  KCONFIG:=CONFIG_NET_DSA_TAG_VSC73XX_8021Q
  FILES:= \
	$(PKG_BUILD_DIR)/src/rtl8372n_dsa.ko \
	$(LINUX_DIR)/net/dsa/tag_vsc73xx_8021q.ko
  AUTOLOAD:=$(call AutoLoad,99,rtl8372n_dsa)
  DEPENDS:=+kmod-dsa +kmod-regmap-core
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)/src" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		CONFIG_RTL8372N_DSA=m \
		CONFIG_RTL837X_PHY_PATCH=n \
		CONFIG_RTL8372N_DSA_DEBUG=n \
		modules
endef

$(eval $(call KernelPackage,rtl837x-dsa))
