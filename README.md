# QEMU Linux Hello World

A Bash script that creates and boots a minimal AMD64 Linux system using QEMU. The guest prints `hello world` during startup and shuts down automatically without requiring a login.

The script downloads a prebuilt Linux kernel, verifies its SHA-256 checksum, creates an initramfs using BusyBox, and launches the system through QEMU.

## Requirements

Developed and tested on Ubuntu 26.04.1 LTS using QEMU 10.2.1.

Required tools:
- Bash
- QEMU (`qemu-system-x86_64`)
- Statically linked BusyBox
- `fakeroot`, `cpio`, `gzip`
- `curl`, `dpkg-deb`, `sha256sum`
- Standard Linux utilities

## Running

```bash
git clone https://github.com/Smalera93/qemu-linux-hello.git
cd qemu-linux-hello
./run.sh
```

The script automatically prepares the filesystem, downloads the kernel if necessary, starts QEMU and checks the boot output.

Generated files, downloads and boot logs are stored within the project directory under `build/` and `downloads/`.

## Implementation

- Kernel: Ubuntu Linux 7.0.0-42-generic (AMD64), downloaded and checksum-verified.

- Filesystem: Minimal initramfs containing a statically linked BusyBox and /init startup script.

- Boot: QEMU direct kernel loading with software CPU emulation (TCG).

- Verification: Checks the serial-console log for hello world and successful shutdown.

The script does not install packages, require root privileges during execution or modify the host's operating system. Required tools must be installed beforehand.

The project uses QEMU's direct kernel-loading method rather than a firmware-bootable disk image.
