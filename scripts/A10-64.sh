#!/usr/bin/env bash
rm -rf kernel
git clone $REPO -b $BRANCH kernel 
cd kernel
echo "Nuke previous toolchains"
rm -rf toolchain out AnyKernel
echo "cleaned up"
echo "Cloning toolchain"
git clone --depth=1 https://github.com/rokibhasansagar/linaro-toolchain-latest.git -b latest-4 gcc-64
echo "Done"
if [ "$is_test" = true ]; then
     echo "Its alpha test build"
     unset chat_id
     unset token
     export chat_id=${my_id}
     export token=${nToken}
else
     echo "Its beta release build"
fi
SHA=$(echo $DRONE_COMMIT_SHA | cut -c 1-8)
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +'%H%M-%d%m%y')
START=$(date +"%s")
CODENAME=j6primelte
DEF=j6primelte_defconfig
CCACHE_DIR="~/.ccache"
export CROSS_COMPILE="$(pwd)/gcc-64/bin/aarch64-linux-gnu-"
export PATH="$(pwd)/gcc-64/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_USER=malkist
export KBUILD_BUILD_HOST=android
export USE_CCACHE=1
export CCACHE_DIR="${CCACHE_DIR}"
ccache -M 50G
# Push kernel to channel
function push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Samsung J6+</b>"
}
# Compile plox
function compile() {
     make -C $(pwd) O=out ${DEF}
     make -j64 -C $(pwd) O=out

     if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
     fi
    git clone --depth=1 https://github.com/malkist01/anykernel3.git AnyKernel -b master
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 Teletubies-A10-"${CODENAME}"-Arm64-"${DATE}".zip ./*
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
