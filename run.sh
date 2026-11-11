#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

REQUIRED_TOOLS=(
	"qemu-system-x86_64"
	"cpio"
	"gzip"
	"busybox"
	"fakeroot"
	"curl"
	"find"
	"mknod"
)

check_dependency() {
	local tool="$1"

	if ! command -v "$tool" > /dev/null 2>&1; then
		echo "Error: required command '$tool' is not installed." >&2
		exit 1
	fi
}

for tool in "${REQUIRED_TOOLS[@]}"; do
	check_dependency "$tool"
done

echo "Preparing guest filesystem..."

mkdir -p build
mkdir -p downloads
rm -rf -- "$PROJECT_DIR/build/rootfs"
mkdir -p build/rootfs/{bin,dev,proc,sys}

cp "$(command -v busybox)" build/rootfs/bin/busybox
ln -sfn busybox build/rootfs/bin/sh
install -m 0755 initramfs/init build/rootfs/init
echo "Guest filesystem prepared."

echo "Creating initramfs archive..."

fakeroot -- bash -euo pipefail -c '
	cd build/rootfs

	mknod -m 600 dev/console c 5 1
	mknod -m 666 dev/null c 1 3

	find . -print0 |
		cpio --null -o --format=newc --owner=0:0 |
		gzip -9 -n > ../initramfs.cpio.gz
'
echo "Initramfs archive created."
