# OSDev-Tools

Docker container with a `gcc` cross compiler toolchain for building and
debugging operating systems.

Image available on Docker Hub at: `jprx/osdev-tools`

## Installed Tools

- `x86_64-elf-gcc` (with red zone disabled in `libgcc`)
- `aarch64-elf-gcc`
- `riscv64-elf-gcc`
- `x86_64-elf-gdb`
- `aarch64-elf-gdb`
- `riscv64-elf-gdb`
- `x86_64-elf-g++`
- `aarch64-elf-g++`
- `riscv64-elf-g++`
- Binutils toolchain (`as`, `ld`, `objcopy`, `objdump`, etc.) for `x86_64`, `aarch64`, and `riscv64`.
  - Each tool is referred to by the triple `$(ARCH)-elf-$(TOOL)`
- `make`
- `bear`
- `genext2fs`
- `grub` and `xorriso` (for building bootable PC ISOs)

## Usage

Installation: `docker pull jprx/osdev-tools`

Usage: `docker run --rm -ti -v .:/src -w /src jprx/osdev-tools`

This will mount the current working directory inside the container at `/src`.

## References

- [OSDev Wiki: GCC Cross Compiler](https://wiki.osdev.org/GCC_Cross-Compiler)
- [OSDev Wiki: Libgcc without red zone](https://wiki.osdev.org/Libgcc_without_red_zone)
- [OSDev Wiki: Target Triplet](https://wiki.osdev.org/Target_Triplet)
