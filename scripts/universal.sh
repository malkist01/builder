#!/usr/bin/env bash
rm -rf kernel
git clone $REPO -b $BRANCH kernel 
cd kernel
curl -LSs "https://raw.githubusercontent.com/rsuntk/KernelSUonArm32/main/kernel/setup.sh" | bash -s main
echo "Nuke previous toolchains"
rm -rf toolchain out AnyKernel
echo "cleaned up"
echo "Cloning toolchain"
git clone --depth=1 https://github.com/ryan-andri/aarch64-linaro-linux-gnu-4.9.git -b master gcc-64
# Speed up the build
CCACHE=true
unset CLANG_ROOT
unset CLANG_PATH
unset LD_LIBRARY_PATH
unset CLANG_TRIPLE
unset CC
unset CLANG_SRC
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
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DATE=$(date +'%H%M-%d%m%y')
START=$(date +"%s")
CODENAME=A7XLTE
DEF=nethunter_defconfig
MAKE_ARGS="CONFIG_NO_ERROR_ON_MISMATCH=y"
export CROSS_COMPILE="$(pwd)/gcc-64/bin/aarch64-linux-gnu-"
export PATH="$(pwd)/gcc-64/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_USER=malkist
export KBUILD_BUILD_HOST=a7exlte
# Push kernel to channel
function push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Samsung A7 2016</b>"
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
    cp out/arch/arm64/boot/Image AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 Teletubies-"${CODENAME}"-"${DATE}".zip ./*
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
