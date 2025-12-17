#!/bin/bash

echo -e "\n[INFO]: BUILD STARTED..!\n"

#init submodules
#git submodule init && git submodule update

export KERNEL_ROOT="$(pwd)"
export ARCH=arm64
export KBUILD_BUILD_USER="Kebab"

# Create necessary directories
mkdir -p "${KERNEL_ROOT}/out" "${HOME}/toolchains"

# Export toolchain paths
export PATH="${HOME}/toolchains/clang-r383902b1/bin:${PATH}"
export LD_LIBRARY_PATH="${HOME}/toolchains/clang-r383902b1/lib:${LD_LIBRARY_PATH}"

# Set cross-compile environment variables
export BUILD_CROSS_COMPILE_COMPAT="${HOME}/toolchains/gcc-arm/bin/arm-linux-androideabi-"
export BUILD_CROSS_COMPILE="${HOME}/toolchains/gcc/bin/aarch64-linux-androidkernel-"
export BUILD_CC="${HOME}/toolchains/clang-r383902b1/bin/clang"
# Build options for the kernel
export BUILD_OPTIONS="
-C ${KERNEL_ROOT} \
O=${KERNEL_ROOT}/out \
-j$(nproc) \
ARCH=arm64 \
CROSS_COMPILE=${BUILD_CROSS_COMPILE} \
CROSS_COMPILE_COMPAT=${BUILD_CROSS_COMPILE_COMPAT} \
LINUX_GCC_CROSS_COMPILE_PREBUILTS_BIN=${HOME}/gcc/aarch64-linux-android/bin \
LINUX_GCC_CROSS_COMPILE_ARM32_PREBUILTS_BIN=${HOME}/gcc-arm/arm-linux-androideabi/bin \
CC=${BUILD_CC} \
CLANG_TRIPLE=aarch64-linux-gnu- \
LD=ld.lld \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
CLANG_PREBUILT_BIN="${HOME}/toolchains/clang-r383902b1/bin" \
DEPMOD=depmod \
"
build_kernel(){
    make ${BUILD_OPTIONS} clean
    make ${BUILD_OPTIONS} mrproper
    make ${BUILD_OPTIONS} stock_defconfig

     nano out/.config

    # Build the kernel
    make ${BUILD_OPTIONS} Image || exit 1
    cat out/arch/arm64/boot/Image | gzip -n -f -9 > out/arch/arm64/boot/Image1.gz
    cp out/arch/arm64/boot/Image ${HOME}/kernels
    cd ${HOME}/kernels
    ./patch_linux Image
    cd $KERNEL_ROOT
    mv ../oImage out/arch/arm64/boot/Image
    cat out/arch/arm64/boot/Image | gzip -n -f -9 > out/arch/arm64/boot/Image.gz
    # Copy the built kernel to the build directory
    cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image1.gz" /mnt/hgfs/Firm
    cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image.gz" /mnt/hgfs/Firm

    echo -e "\n[INFO]: BUILD FINISHED..!"
}
build_kernel
