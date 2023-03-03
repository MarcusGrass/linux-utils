# Compile kernel with Clang and LTO
```bash
# Menuconfig needs clang to expose LTO option
make CC=clang LLVM=1 menuconfig
# Build kernel
make CC=clang LLVM=1 -j$(nproc)
# Install modules
make CC=clang LLVM=1 modules_install
# Make sure boot is mounted to /boot
make CC=clang LLVM=1 install
# Generate initramfs
dracut --kver=6.1.16-gentoo -f
# Generate grub cfg
grub-mkconfig -o /boot/grub/grub.cfg
```