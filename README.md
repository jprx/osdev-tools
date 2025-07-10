# OSDev-Tools

Precompiled `gcc` cross compilers for `x86_64`, `aarch64`, and `riscv64` bare
metal targets. For `x86_64`, the red zone is disabled in `libgcc` so that
interrupts can push stack frames freely without worrying about clobbering red
zone data.

**TLDR**: Use this for compiling your kernels or bare metal programs.

You can find a prebuilt multi platform container image in Docker Hub at
`jprx/osdev-tools`.

## Installed Tools

This container installs `binutils`, `gcc`, and `gdb` for `x86_64`, `aarch64`,
and `riscv64` targets. This includes tools such as `as`, `ld`, `objdump`,
`objcopy`, `gcc`, and `g++`. All projects are built into `/cross` inside the
container. For a complete list of available tools, inspect `/cross/bin` inside
the container.

Each tool is prefixed by its target triplet (omitting the vendor field), which
looks like `$(ARCH)-elf-$(TOOL)`. For example, to use `gcc` for an `x86_64`
build, you would use `x86_64-elf-gcc`. To use `ld` for an `aarch64` target, you
would use `aarch64-elf-ld`.

To eliminate confusion, the only tools available inside the container are cross
compilers: no native compiler is included. So, there is no `gcc` installed- you
must explicitly select one of the cross compiler tools by prefixing the
architecture to the command.

## Usage

Installation: `docker pull jprx/osdev-tools`

Usage: `docker run --rm -ti -v .:/src -w /src jprx/osdev-tools`

This will mount the current working directory inside the container at `/src`,
where you can use the cross compiler toolchain on the files on your host
system.

## References

- [OSDev Wiki: GCC Cross Compiler](https://wiki.osdev.org/GCC_Cross-Compiler)
- [OSDev Wiki: Libgcc without red zone](https://wiki.osdev.org/Libgcc_without_red_zone)
- [OSDev Wiki: Target Triplet](https://wiki.osdev.org/Target_Triplet)
