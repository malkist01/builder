#!/usr/bin/env bash
#
# Copyright (C) 2023 Edwiin Kusuma Jaya (ryuzenn)
# Copyright (C) 2025 k4ngcaribug
# Simple Local Kernel Build Script
#
# Configured for Redmi Note 8 / ginkgo custom kernel source
#
# Setup build env with akhilnarang/scripts repo
#
# Use this script on root of kernel directory
# Dependencies
rm -rf kernel
git clone $REPO -b $BRANCH kernel 
cd kernel
rm -rf KernelSU
git clone --depth=1 -b 17 https://gitlab.com/nekoprjkt/aosp-clang
echo "Cloning failed! Aborting..."

SECONDS=0 # builtin bash timer
ZIPNAME="Venom-X1-Ginkgo-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
ZIPNAME_KSU="Venom-X1-Ginkgo-KSU-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
TC_DIR="$HOME/tc/"
CLANG_DIR="${TC_DIR}clang"
GCC_64_DIR="${TC_DIR}aarch64-linux-android-4.9"
GCC_32_DIR="${TC_DIR}arm-linux-androideabi-4.9"
AK3_DIR="$HOME/AnyKernel3"
DEFCONFIG="teletubies_defconfig"

KBUILD_BUILD_HOST="android"
export KBUILD_BUILD_HOST
KBUILD_BUILD_USER="malkist"
export KBUILD_BUILD_USER
DEVICE="Xiaomi Redmi Note 4"
export DEVICE
CODENAME="mido"
export CODENAME
COMMIT_HASH=$(git rev-parse --short HEAD)
export COMMIT_HASH

export PATH="$CLANG_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$CLANG_DIR/lib:$LD_LIBRARY_PATH"
export KBUILD_BUILD_VERSION="1"
export LOCALVERSION

tg() {
    curl -sX POST https://api.telegram.org/bot"${token}"/sendMessage -d chat_id="${chat_id}" -d parse_mode=Markdown -d disable_web_page_preview=true -d text="$1" &>/dev/null
}

tgs() {
    MD5=$(md5sum "$1" | cut -d' ' -f1)
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${token}"/sendDocument \
        -F "chat_id=${chat_id}" \
        -F "parse_mode=Markdown" \
        -F "caption=$2 | *MD5*: \`$MD5\`"
}

# Send Build Info
sendinfo() {
    tg "
• Compiler Action •
*Building on*: \`Github actions\`
*Date*: \`${DATE}\`
*Device*: \`${DEVICE} (${CODENAME})\`
*Branch*: \`$(git rev-parse --abbrev-ref HEAD)\`
*Last Commit*: [${COMMIT_HASH}](${REPO}/commit/${COMMIT_HASH})
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Build Status*: \`${STATUS}\`"
}

# Push kernel to channel
push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    tgs "${ZIP}" "Build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s). | For *${DEVICE} (${CODENAME})* | ${KBUILD_COMPILER_STRING}"
}

# Catch Error
finderr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d sticker="CAADBQADZwADqZrmFoa87YicX2hwAg" \
        -d text="Build throw an error(s)"
    error_sticker
    exit 1
}

# Now let's clone gcc/clang on HOME dir
# And after that , the script start the compilation of the kernel it self
# For regen the defconfig . use the regen.sh script

# Set function for override kernel name and variants
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
echo -e "\nKSU Support, let's Make it On\n"
curl -LSs "https://raw.githubusercontent.com/KernelSu-Next/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs
git apply KernelSU-hook.patch
sed -i 's/CONFIG_KSU=n/CONFIG_KSU=y/g' arch/arm64/configs/teletubies_defconfig
else
echo -e "\nKSU not Support, let's Skip\n"
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out \
					  ARCH=arm64 \
					  CC=clang \
					  LD=ld.lld \
					  AR=llvm-ar \
					  AS=llvm-as \
					  NM=llvm-nm \
					  OBJCOPY=llvm-objcopy \
					  OBJDUMP=llvm-objdump \
					  STRIP=llvm-strip \
					  CROSS_COMPILE=aarch64-linux-android- \
					  CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
					  CLANG_TRIPLE=aarch64-linux-gnu- \
					  Image.gz-dtb \
					  dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git restore arch/arm64/configs/teletubies_defconfig
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -q https://github.com/k4ngcaribug/AnyKernel3; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout main &> /dev/null
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
zip -r9 "../$ZIPNAME_KSU" * -x '*.git*' README.md *placeholder
else
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
fi
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
echo "Zip: $ZIPNAME_KSU"
else
echo "Zip: $ZIPNAME"
fi
else
echo -e "\nCompilation failed!"
exit 1
fi
echo -e "======================================="
END=$(date +"%s")
DIFF=$((END - START))
push
git restore .
