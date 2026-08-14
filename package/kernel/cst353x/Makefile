#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=cst353x
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-or-later

include $(INCLUDE_DIR)/package.mk

define KernelPackage/input-touchscreen-cst353x
  SUBMENU:=Input modules
  TITLE:=Hynitron CST353X touchscreen
  DEPENDS:=+kmod-i2c-core +kmod-input-core
  KCONFIG:=CONFIG_INPUT_TOUCHSCREEN=y
  FILES:=$(PKG_BUILD_DIR)/cst353x.ko
  AUTOLOAD:=$(call AutoProbe,cst353x)
endef

define KernelPackage/input-touchscreen-cst353x/description
 Driver for the Hynitron CST353X capacitive touch controller, as fitted to
 the GL.iNet BE10000. The controller answers on i2c at address 0x58 and
 uses 32 bit register addresses, which the mainline hynitron_cstxxx driver
 does not support.
endef

define Build/Compile
	$(KERNEL_MAKE) M="$(PKG_BUILD_DIR)" modules
endef

$(eval $(call KernelPackage,input-touchscreen-cst353x))
