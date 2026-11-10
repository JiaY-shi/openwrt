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

define Device/glinet_gl-be3600
	# LZMA, not gzip: stock kernel FIT is lzma and the stock U-Boot's
	# decompression support is unverified beyond that (gzip FIT boot-looped
	# in testing).
	$(call Device/FitImageLzma)
	$(call Device/UbiFit)
	DEVICE_VENDOR := GL.iNet
	DEVICE_MODEL := GL-BE3600
	DEVICE_ALT0_VENDOR := GL.iNet
	DEVICE_ALT0_MODEL := Slate 7
	# The shipped U-Boot's board table CONTAINS mi04.1-c2 (verified by
	# strings on a live unit's 0:appsbl: "config@mi04.1-c2"), so bootipq
	# requests that config name from the kernel FIT. (GL's 4.9.x stock
	# kernel FIT carries only config-1, which suggests newer GL uboots ask
	# differently - if a unit with updated uboot loops, revisit with a
	# dual-config FIT.)
	DEVICE_DTS_CONFIG := config@mi04.1-c2
	SOC := ipq5332
	# Stock GL firmware identifies as the bare QSDK reference-board compatible,
	# so list it too - it is what lets stock sysupgrade accept factory.bin
	# without -F. Consequence: any other AP-MI04.1-C2 design reporting that
	# compatible will also accept this image. Accepted deliberately for the
	# stock->OpenWrt hop; there is no per-board warning mechanism for it
	# (DEVICE_COMPAT_MESSAGE only fires on a DEVICE_COMPAT_VERSION change).
	SUPPORTED_DEVICES += gl.inet,gl-be3600 gl-be3600 qcom,ipq5332-ap-mi04.1-c2
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	KERNEL_INSTALL := 1
	# Inherited from the BE6500. With KERNEL_IN_UBI the kernel lives in a
	# dynamic UBI volume sized by ubinize, so this is a build sanity cap,
	# not a partition size.
	KERNEL_SIZE := 6096k
	# The rootfs MTD is 0x1ec00000 (492 MiB). NAND_SIZE must be set too, or
	# append-ubi ignores IMAGE_SIZE and nothing is enforced at all.
	IMAGE_SIZE := 503808k
	NAND_SIZE := 512m
	IMAGES += factory.bin
	BOOT_SCRIPT := gl-be3600-factory.bootscript
	IMAGES += factory.bin
	IMAGE/factory.bin := append-ubi | gl-ipq-factory-nand | append-metadata
	# Hardware support only. Wi-Fi: 2.4 GHz from the integrated IPQ5332
	# radio, 5 GHz from the QCN6432 running as user PD 2 (ath12k patch 320);
	# the QCN6432 firmware ships via the files/ overlay, so there is no
	# ath12k-firmware-qcn* package to select here. The USB 3.0 host port
	# (dwc3 + M31 HS PHY + the retargeted PCIe0/USB combo uniphy, see the DTS)
	# needs only kmod-usb3/usb-dwc3/usb-dwc3-qcom, which the target adds by
	# default. USB storage, filesystems and modem drivers are left to the
	# image configuration (configs/be3600-extra.config).
	DEVICE_PACKAGES := kmod-ath12k ath12k-firmware-ipq5332 \
		ipq-wifi-glinet_gl-be3600 kmod-hwmon-pwmfan kmod-qrtr-smd dumpimage
endef
TARGET_DEVICES += glinet_gl-be3600
