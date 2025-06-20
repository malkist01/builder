#!/usr/bin/env bash
rm -rf kernel
git clone $REPO -b $BRANCH kernel 
cd kernel
echo "Nuke previous toolchains"
rm -rf toolchain out AnyKernel
echo "cleaned up"
echo "Cloning toolchain"
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
IMAGE=$(pwd)/out/arch/arm/boot/zImage-dtb
DATE=$(date +'%H%M-%d%m%y')
START=$(date +"%s")
CODENAME=j6primelte
DEF=j6primelte_defconfig
export PATH="$(pwd)/proton-clang/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_USER=malkist
export KBUILD_BUILD_HOST=android
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
    make -j$(nproc --all) O=out ARCH=arm64 ${DEF}
    make -j$(nproc --all) ARCH=arm64 O=out \
                          CC=clang \
                          CROSS_COMPILE=aarch64-linux-gnu- \
                          CROSS_COMPILE_ARM32=arm-linux-gnueabi-

     if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
     fi
    git clone --depth=1 https://github.com/malkist01/anykernel3.git AnyKernel -b master
    cp out/arch/arm/boot/zImage-dtb AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 Teletubies-"${CODENAME}"-Arm64"${DATE}".zip ./*
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
