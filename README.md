# QEMU Linux Hello World

A minimal AMD64 Linux system booted using QEMU.

The project uses a shell script to prepare a minimal Linux environment, create an initramfs and launch the system in QEMU. The guest prints @hello world@ during startup and shuts down without requiring user login.

## Development Environment

- Ubuntu 26.04.1 LTS
- QEMU 10.2.1
- BusyBox
- Bash
