#!/usr/bin/env bash

set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

KERNEL_PACKAGE="linux-image-7.0.0-42-generic_7.0.0-42.42_amd64.deb"

KERNEL_URL="https://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/$KERNEL_PACKAGE"

KERNEL_PATH="$PROJECT_DIR/downloads/$KERNEL_PACKAGE"

KERNEL_SHA256="179381704964d6b79c8d2bab2f5d51d8679cb13e9bf51a3293e28f90b708c96e"

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
	"dpkg-deb"
	"sha256sum"
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

mkdir -p build
mkdir -p downloads
export TMPDIR="$PROJECT_DIR/build/tmp"

echo "Checking Linux kernel package..."

if [[ ! -f "$KERNEL_PATH" ]]; then
	echo "Downloading Linux kernel..."
	curl -fL --retry 3 --output "$KERNEL_PATH.part" "$KERNEL_URL"
	mv -- "$KERNEL_PATH.part" "$KERNEL_PATH"
else
	echo "Kernel package already exists."
fi

printf '%s  %s\n' "$KERNEL_SHA256" "$KERNEL_PATH" | sha256sum -c -

echo "Preparing guest filesystem..."

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

echo "Extracting Linux kernel..."

KERNEL_EXTRACT_DIR="$PROJECT_DIR/build/kernel-package"

rm -rf -- "$KERNEL_EXTRACT_DIR"
mkdir -p "$KERNEL_EXTRACT_DIR"

dpkg-deb -x "$KERNEL_PATH" "$KERNEL_EXTRACT_DIR"

rm -f -- "$PROJECT_DIR/build/vmlinuz"

install -m 0644 \
    "$KERNEL_EXTRACT_DIR/boot/vmlinuz-7.0.0-42-generic" \
    "$PROJECT_DIR/build/vmlinuz"

echo "Linux kernel prepared."

echo "Starting QEMU..."

BOOT_LOG="$PROJECT_DIR/build/boot.log"

rm -f -- "$BOOT_LOG"

qemu-system-x86_64 \
    -accel tcg \
    -m 256M \
    -kernel "$PROJECT_DIR/build/vmlinuz" \
    -initrd "$PROJECT_DIR/build/initramfs.cpio.gz" \
    -append "console=ttyS0 rdinit=/init" \
    -display none \
    -serial "file:$BOOT_LOG" \
    -monitor none \
    -nic none \
    -no-reboot

echo "Verifying guest boot..."

if ! grep -Fq "hello world" "$BOOT_LOG"; then
    echo "Error: Guest did not print hello world." >&2
    tail -n 30 "$BOOT_LOG" >&2
    exit 1
fi

if ! grep -Fq "reboot: Power down" "$BOOT_LOG"; then
    echo "Error: Guest did not shut down as expected." >&2
    tail -n 30 "$BOOT_LOG" >&2
    exit 1
fi

echo "Success: Linux guest printed hello world and shut down."
