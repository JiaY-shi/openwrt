REQUIRE_IMAGE_METADATA=1
RAMFS_COPY_BIN='fitblk fit_check_sign dumpimage'

gl_be6500_remove_oem_rootfs() {
	local mtdnum
	local ubidev
	local ubivol

	mtdnum=$(find_mtd_index "$CI_UBIPART")
	if [ -z "$mtdnum" ]; then
		echo "Unable to find UBI MTD partition $CI_UBIPART"
		return 1
	fi

	ubidev=$(nand_find_ubi "$CI_UBIPART")
	if [ -z "$ubidev" ]; then
		ubiattach --mtdn="$mtdnum" || return 1
		ubidev=$(nand_find_ubi "$CI_UBIPART")
	fi

	[ -n "$ubidev" ] || return 1

	ubivol=$(nand_find_volume "$ubidev" ubi_rootfs)
	[ -z "$ubivol" ] || {
		echo "Removing legacy ubi_rootfs volume"
		ubirmvol "/dev/$ubidev" --name=ubi_rootfs || return 1
	}
}

gl_be6500_do_upgrade_fit() {
	local img="$1"
	local mtdnum
	local ubidev
	local ubivol
	local pos

	# Stock GL.iNet firmware is a QSDK-style FIT image carrying a
	# single "ubi" section. Extract it and write it to the UBI
	# partition, exactly like the stock upgrade routine does.
	pos=$(dumpimage -l "$img" | grep "(ubi)" | awk '{print $2}')
	[ -n "$pos" ] || {
		echo "Unable to find ubi section in $img"
		return 1
	}

	dumpimage -o /tmp/ubi.bin -T flat_dt -p "$pos" "$img" || {
		echo "Unable to extract ubi section from $img"
		return 1
	}

	mtdnum=$(find_mtd_index "$CI_UBIPART")
	[ -n "$mtdnum" ] || {
		echo "Unable to find UBI MTD partition $CI_UBIPART"
		return 1
	}

	# The running root filesystem sits on an UBI block device of this
	# partition. Remove all UBI block devices before detaching,
	# otherwise ubidetach and ubiformat will fail.
	ubidev=$(nand_find_ubi "$CI_UBIPART")
	if [ -n "$ubidev" ]; then
		for ubivol in /dev/${ubidev}_*; do
			[ -e "$ubivol" ] || continue
			nand_remove_ubiblock "${ubivol##*/}" || return 1
		done
		ubidetach -p "/dev/mtd$mtdnum" || return 1
	fi

	ubiformat "/dev/mtd$mtdnum" -y -f /tmp/ubi.bin
}

platform_do_upgrade() {
	case "$(board_name)" in
	qcom,ipq5332-ap-mi01.2 |\
	gl.inet,gl-be6500)
		CI_UBIPART="rootfs"
		if dumpimage -l "$1" >/dev/null 2>&1; then
			gl_be6500_do_upgrade_fit "$1"
		else
			gl_be6500_remove_oem_rootfs || return 1
			nand_do_upgrade "$1"
		fi
		;;
	ubnt,u7-pro-xgs)
		CI_KERNPART="kernel0"
		fit_do_upgrade "$1"
		;;
	*)
		echo "Sysupgrade is not supported on your board yet."
		return 1
		;;
	esac
}

platform_check_image() {
	[ "$#" -gt 1 ] && return 1

	case "$(board_name)" in
	qcom,ipq5332-ap-mi01.2 |\
	gl.inet,gl-be6500)
		if dumpimage -l "$1" >/dev/null 2>&1; then
			# Stock firmware FIT images must carry a "ubi" section
			dumpimage -l "$1" | grep -q "(ubi)" && return 0
			echo "Invalid image: no ubi section found"
			return 1
		fi
		return 0
		;;
	ubnt,u7-pro-xgs)
		fit_check_image "$1"
		;;
	*)
		echo "Sysupgrade is not supported on your board yet."
		return 1
		;;
	esac
}

platform_copy_config() {
	case "$(board_name)" in
	ubnt,u7-pro-xgs)
		emmc_copy_config
		;;
	esac
}
