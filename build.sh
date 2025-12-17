#!/bin/bash
# Compile script for D8G-kernel

SECONDS=0 # builtin bash timer
# TC_DIR="/build1/kernel/gclang"
TC_DIR="/home/nassar/toolchains/LLVM-20.1.6-Linux-X64"
AK3_DIR="AnyKernel3"
# DEFCONFIG="vendor/vili-qgki_defconfig"
DEFCONFIG="new-vili_defconfig"
# DEFCONFIG="kangaroox-vili_defconfig"
BASEDEFCONFIG="vendor/kgbase.config"
CURRNT_DIR=$(pwd)
if [ "$(grep "OVERCLOCK" arch/arm64/configs/new-vili_defconfig |grep -v "#"|head -1|awk -F= '{print $NF}')" == "y" ]; then
	echo -e "\nOverclocking enabled in defconfig, using kgbase.config as base.\n"
	ZIPNAME="RED-OCUV-vili-$(date '+%Y%m%d-%H%M').zip"
else
	echo -e "\nOverclocking disabled in defconfig, using new-vili_defconfig as base.\n"
	ZIPNAME="RED-vili-$(date '+%Y%m%d-%H%M').zip"
fi
# ZIPNAME="RED-vili-$(date '+%Y%m%d-%H%M').zip"

MAKE_PARAMS="O=out \
	ARCH=arm64  \
 	CC=$TC_DIR/bin/clang  \
	CLANG_TRIPLE=$TC_DIR/bin/aarch64-linux-gnu- \
	CROSS_COMPILE=$TC_DIR/bin/aarch64-linux-gnu-  \
	CROSS_COMPILE_ARM32=$TC_DIR/bin/arm-linux-gnueabi-  \
	LLVM=1 \
	LLVM_IAS=1 \
	TARGET_PRODUCT=vili"

export PATH="$TC_DIR/bin:$PATH"
export TARGET_PRODUCT=vili

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	echo -e "\nCleaning source tree...\n"
	make ARCH=arm64 mrproper
	rm -rf out
	echo -e "\nSource tree cleaned successfully!"
	exit
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
	rm -rf out
	mkdir -p out
	cp arch/arm64/configs/$BASEDEFCONFIG out/.config
	make $MAKE_PARAMS olddefconfig
	# cat out/.config | sed 's/\=m/\=y/g' | tee out/.config 
	make $MAKE_PARAMS savedefconfig
	cp out/.config ./arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

# Clean and prepare for build
#echo -e "\nCleaning any previous build artifacts...\n"
#make ARCH=arm64 mrproper
#rm -rf out

#mkdir -p out
#cp arch/arm64/configs/$DEFCONFIG out/.config
#make $MAKE_PARAMS olddefconfig
#make $MAKE_PARAMS menuconfig
#exit
echo -e "\nStarting compilation...\n"
# MAKE WITH logs
set -o pipefail
#make $MAKE_PARAMS $DEFCONFIG
make -j$(nproc --all) $MAKE_PARAMS 2>&1 | tee build.log
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
	echo -e "\nCompilation failed! Check build.log for details."
	exit 1
fi
set +o pipefail
if [ $? -ne 0 ]; then
	echo -e "\nCompilation failed! Check build.log for details."
	exit 1
fi

kernel="out/arch/arm64/boot/Image"
cp out/arch/arm64/boot/Image ../ && cd ../ && ./patch_linux Image && mv oImage $CURRNT_DIR/$kernel && cd $CURRNT_DIR
cp $kernel AnyKernel3
cp out/arch/arm64/boot/dtb.img AnyKernel3/dtb.img
cp out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img

cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
cd ..
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
cp $ZIPNAME /mnt/hgfs/Firm
