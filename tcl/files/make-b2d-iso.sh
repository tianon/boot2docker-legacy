#!/usr/bin/env bash
set -Eeuo pipefail

find -not -name '*.tcz' \
	| cpio --create --format newc --dot \
	| xz -9 --format=lzma --verbose --verbose --threads=0 --extreme \
	> /tmp/iso/boot/initrd.img

xorriso \
	-as mkisofs -o /tmp/boot2docker.iso \
	-A 'Boot2Docker' -V 'Boot2Docker' \
	-isohybrid-mbr /tmp/isohdpfx.bin \
	-partition_offset 16 \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	/tmp/iso

mkdir -p /tmp/stats
(
	cd /tmp
	echo '```console'
	for cmd in sha512sum sha256sum sha1sum md5sum; do
		echo "\$ $cmd boot2docker.iso"
		"$cmd" boot2docker.iso
	done
	echo '```'
) | tee /tmp/stats/sums.md
{
	echo "- Docker [v$DOCKER_VERSION](https://github.com/docker/docker-ce/releases/tag/v$DOCKER_VERSION)"

	echo "- Linux [v$LINUX_VERSION](https://cdn.kernel.org/pub/linux/kernel/v4.x/ChangeLog-$LINUX_VERSION)"

	aufsVersion="$(awk '$1 == "#define" && $2 == "AUFS_VERSION" { gsub(/^"|"$/, "", $3); print $3 }' /usr/src/aufs/include/uapi/linux/aufs_type.h)"
	aufsUtilVersion="$(awk '$1 == "#define" && $2 == "AuRelease" { gsub(/^"|"$/, "", $3); print $3 }' /usr/src/aufs-util/au_util.h)"
	echo "- AUFS [v$aufsVersion](https://github.com/sfjro/aufs4-standalone/commit/$AUFS_COMMIT), utilities [$AUFS_UTIL_BRANCH-$aufsUtilVersion](https://sourceforge.net/p/aufs/aufs-util/ci/$AUFS_UTIL_COMMIT)"

	echo "- Parallels Tools v$PARALLELS_VERSION" # TODO link?

	ovtVersion="$(tcl-chroot vmtoolsd --version | grep -oE 'version [^ ]+' | cut -d' ' -f2)"
	echo "- VMware Tools (\`open-vm-tools\`) [v$ovtVersion](http://distro.ibiblio.org/tinycorelinux/$TCL_MAJOR/x86_64/tcz/open-vm-tools.tcz.info)"

	echo "- VirtualBox Guest Additions [v$VBOX_VERSION](https://download.virtualbox.org/virtualbox/$VBOX_VERSION/)"

	echo "- XenServer Tools (\`xe-guest-utilities\`) [v$XEN_VERSION](https://github.com/xenserver/xe-guest-utilities/tree/v$XEN_VERSION)"
} | tee /tmp/stats/state.md
