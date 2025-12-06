#!/usr/bin/env bash
# Dependencies
rm -rf kernel
mkdir -p -v $HOME/clang
aria2c -o clang-r547379.tar.gz https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz
tar -C $HOME/clang -zxf clang-r547379.tar.gz
mkdir -p -v $HOME/gcc
aria2c -o gcc-aarch64.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/0a0604336d4d1067aa1aaef8d3779b31fcee841d.tar.gz
tar -C $HOME/gcc -zxf gcc-aarch64.tar.gz
mkdir -p -v $HOME/gcc32
aria2c -o gcc-arm.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/4d16d93f49c2b5ecdd0f12c38d194835dd595603.tar.gz
tar -C $HOME/gcc32 -zxf gcc-arm.tar.gz
git clone $REPO -b $BRANCH kernel
cd kernel
echo "Done"
export PATH=$HOME/clang/bin:$HOME/gcc/bin:$HOME/gcc32/bin:$PATH
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
DTB=$(pwd)/out/arch/arm64/boot/dtbo.img
DATE=$(date +"%Y%m%d-%H%M")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
#Ccache
export USE_CCACHE=1
export TZ=Asia/Jakarta
export KBUILD_COMPILER_STRING
ARCH=arm64
export ARCH
CC=clang
export CC
KBUILD_BUILD_HOST="android"
export KBUILD_BUILD_HOST
KBUILD_BUILD_USER="malkist"
export KBUILD_BUILD_USER
DEVICE="Redmi Note 8"
export DEVICE
CODENAME="ginkgo"
export CODENAME
DEFCONFIG="vendor/ginkgo-perf_defconfig"
export DEFCONFIG
COMMIT_HASH=$(git rev-parse --short HEAD)
export COMMIT_HASH
PROCS=$(nproc --all)
export PROCS
STATUS=STABLE
export STATUS
BOT_TOKEN="7596553794:AAGoeg4VypmUfBqfUML5VWt5mjivN5-3ah8"
CHAT_ID="-1002287610863"
source "${HOME}"/.bashrc && source "${HOME}"/.profile
if [ $CACHE = 1 ]; then
    ccache -M 100G
    export USE_CCACHE=1
fi
LC_ALL=C
export LC_ALL

tg() {
    curl -sX POST https://api.telegram.org/bot"${BOT_TOKEN}"/sendMessage -d chat_id="${CHAT_ID}" -d parse_mode=Markdown -d disable_web_page_preview=true -d text="$1" &>/dev/null
}

tgs() {
    MD5=$(md5sum "$1" | cut -d' ' -f1)
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${BOT_TOKEN}"/sendDocument \
        -F "chat_id=${CHAT_ID}" \
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
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d sticker="CAADBQADZwADqZrmFoa87YicX2hwAg" \
        -d text="Build throw an error(s)"
    error_sticker
    exit 1
}

# Compile
compile() {

    if [ -d "out" ]; then
        rm -rf out && mkdir -p out
    fi

        make -s -C $(pwd) O=out ${DEFCONFIG}
        make -s -C $(pwd) TRIPLE_COMPILE=${CLANG} CROSS_COMPILE=${GCC} CROSS_COMPILE_ARM32=${GCC32} O=out

    if ! [ -a "$IMAGE" "$DTB" ]; then
        finderr
        exit 1
    fi

    git clone --depth=1 https://github.com/malkist01/anykernel3.git AnyKernel -b master
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
    cp out/arch/arm64/boot/dtbo.img AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 Teletubies-"${BRANCH}"-"${CODENAME}"-"${DATE}".zip ./*
    cd ..
}

clang
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$((END - START))
push
