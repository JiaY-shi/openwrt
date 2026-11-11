DEVICE_VARS += BOOT_SCRIPT

define Build/gl-ipq-factory-nand
	$(CP) $(BOOT_SCRIPT) $(KDIR_TMP)/
	$(TOPDIR)/scripts/mkits-qsdk-ipq-image.sh \
		$@.its \
		$(KDIR_TMP)/$(notdir $(BOOT_SCRIPT)) \
		ubi \
		$@
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@.new
	@mv $@.new $@
	$(RM) $@.its $(KDIR_TMP)/$(notdir $(BOOT_SCRIPT))
endef

define Build/gl-ipq-factory-emmc
	$(TOPDIR)/scripts/mkits-qsdk-ipq-image.sh \
		$@.its $(CURDIR)/$(BOOT_SCRIPT) hlos $(IMAGE_KERNEL) rootfs $@
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@.new
	@mv $@.new $@
	$(RM) $@.its
endef

define Build/fit-inline-rootfs
	rm -f $@.dtb $@.kernel
	cp $@ $@.kernel
	cp $(word 2,$(1)) $@.dtb
	cp $@.kernel $@
	$(call Build/fit-its,$(word 1,$(1)) $@.dtb with-rootfs)
	$(call Build/fit-image,$(word 1,$(1)) $@.dtb with-rootfs)
	kernel_size="$$(stat -c%s $@.kernel)"; \
	rootfs_offset="$$(grep -oba hsqs $@ | \
		awk -F: -v limit="$$kernel_size" '$$1 >= limit {print $$1; exit}')"; \
	[ -n "$$rootfs_offset" ] || { echo "Failed to locate SquashFS in $@"; exit 1; }; \
	pad="$$(( (4096 - ($$rootfs_offset % 4096)) % 4096 ))"; \
	cp $(word 2,$(1)) $@.dtb; \
	dd if=/dev/zero bs=1 count="$$pad" >> $@.dtb 2>/dev/null; \
	cp $@.kernel $@; \
	$(call Build/fit-its,$(word 1,$(1)) $@.dtb with-rootfs)
	$(call Build/fit-image,$(word 1,$(1)) $@.dtb with-rootfs)
	kernel_size="$$(stat -c%s $@.kernel)"; \
	rootfs_offset="$$(grep -oba hsqs $@ | \
		awk -F: -v limit="$$kernel_size" '$$1 >= limit {print $$1; exit}')"; \
	[ "$$(( $$rootfs_offset % 4096 ))" -eq 0 ] || { echo "SquashFS is misaligned in $@"; exit 1; }; \
	rm -f $@.dtb $@.kernel
endef

define Device/ubnt_u7-pro-xgs
	DEVICE_VENDOR := Ubiquiti
	DEVICE_MODEL := UniFi U7 Pro XGS
	# Stock U-Boot probes config-a6a4 on this board.
	DEVICE_DTS_CONFIG := config-a6a4
	SOC := ipq5332
	SUPPORTED_DEVICES += ubnt,u7-pro-xgs
	DEVICE_PACKAGES := e2fsprogs f2fsck fitblk mkf2fs \
		kmod-ath12k ath12k-firmware-qcn9274 \
		ipq-wifi-ubnt_u7-pro-xgs kmod-leds-pwm \
		kmod-phy-realtek rtl826x-firmware
	KERNEL := kernel-bin | lzma
	KERNEL_INITRAMFS := kernel-bin | lzma | \
		fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
	KERNEL_INITRAMFS_SUFFIX := .itb
	IMAGE_SIZE := 32m
	IMAGES := sysupgrade.itb
	IMAGE/sysupgrade.itb := append-kernel | \
		fit-inline-rootfs lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb | \
		check-size | append-metadata
endef
TARGET_DEVICES += ubnt_u7-pro-xgs

define Device/glinet_gl-be6500
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := GL.iNet
	DEVICE_MODEL := GL-BE6500
	DEVICE_DTS_CONFIG := config@mi01.2
	SOC := ipq5332
	SUPPORTED_DEVICES += gl.inet,gl-be6500 gl-be6500 qcom,ipq5332-ap-mi01.2
	BLOCKSIZE := 256k
	PAGESIZE := 4096
	KERNEL_INSTALL := 1
	KERNEL_SIZE := 6096k
	IMAGE_SIZE := 25344k
	BOOT_SCRIPT := glinet_gl-be6500.bootscript
	IMAGES += factory.bin
	IMAGE/factory.bin := append-ubi | gl-ipq-factory-nand | append-metadata
	DEVICE_PACKAGES := kmod-ath12k ath12k-firmware-ipq5332 \
		ath12k-firmware-qcn9274 ipq-wifi-glinet_gl-be6500 \
		kmod-hwmon-pwmfan kmod-qrtr-smd kmod-rtl837x-dsa \
		kmod-usb-storage kmod-usb-storage-uas blockd usbutils dumpimage
endef
TARGET_DEVICES += glinet_gl-be6500

define Device/glinet_gl-be9300
	$(call Device/FitImage)
	$(call Device/EmmcImage)
	DEVICE_VENDOR := GL.iNet
	DEVICE_MODEL := GL-BE9300
	DEVICE_ALT0_VENDOR := GL.iNet
	DEVICE_ALT0_MODEL := Flint 3
	# Stock bootipq falls back to config-1 for AP-MI01.6.
	DEVICE_DTS_CONFIG := config-1
	SOC := ipq5332
	SUPPORTED_DEVICES += gl.inet,gl-be9300 gl-be9300
	# The factory 0:HLOS eMMC partition is 7 MiB.
	KERNEL_SIZE := 7168k
	KERNEL_INSTALL := 1
	BOOT_SCRIPT := glinet_gl-be9300.bootscript
	IMAGE/factory.bin := append-rootfs | pad-rootfs | pad-to 64k | \
		gl-ipq-factory-emmc | append-gl-metadata
	DEVICE_PACKAGES := kmod-ath12k ath12k-firmware-ipq5332 \
		ath12k-firmware-qcn9274 ipq-wifi-glinet_gl-be9300 \
		kmod-hwmon-pwmfan kmod-qrtr-smd kmod-rtl837x-dsa \
		kmod-phy-realtek f2fsck mkf2fs dumpimage \
		kmod-usb-storage kmod-usb-storage-uas blockd usbutils
endef
TARGET_DEVICES += glinet_gl-be9300
