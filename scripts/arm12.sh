#!/usr/bin/env bash
rm -rf kernel
git clone $REPO -b $BRANCH kernel 
cd kernel
curl -LSs "https://raw.githubusercontent.com/malkist01/patch/main/fs/patch.sh" | bash -s main
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s v1.1.1
         cd KernelSU-Next
         wget https://raw.githubusercontent.com/ThRE-Team/KSU/refs/heads/next-susfs/0001-add-susfs-v1.5.5.patch
         patch -p1 < 0001-add-susfs-v1.5.5.patch
         cd ..
         
         git clone --depth=1 https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.9 susfs4ksu
         cp susfs4ksu/kernel_patches/fs/* ./fs
         cp susfs4ksu/kernel_patches/include/linux/* ./include/linux
         cp susfs4ksu/kernel_patches/50_add_susfs_in_kernel-4.9.patch ./
         patch -p1 < 50_add_susfs_in_kernel-4.9.patch

         make mrproper
echo "Nuke previous toolchains"
rm -rf toolchain out AnyKernel
echo "cleaned up"
echo "Cloning toolchain"
git clone --depth=1 https://github.com/KudProject/arm-linux-androideabi-4.9.git -b master gcc32
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
IMAGE=$(pwd)/out/arch/arm/boot/zImage
DATE=$(date +'%H%M-%d%m%y')
START=$(date +"%s")
CODENAME=j6primelte
DEF=j6primelte_defconfig
export CROSS_COMPILE="$(pwd)/gcc32/bin/arm-linux-androideabi-"
export PATH="$(pwd)/gcc32/bin:$PATH"
export ARCH=arm
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
     make -C $(pwd) O=out ${DEF}
     make -j64 -C $(pwd) O=out
     if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
     fi
    git clone --depth=1 https://github.com/malkist01/anykernel3.git AnyKernel -b master
    cp out/arch/arm/boot/zImage AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 Teletubies-KSU-"${CODENAME}"-arm-"${DATE}".zip ./*
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
