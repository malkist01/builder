#!/usr/bin/env bash
# Set Environment Configs
OUT=$(pwd)/out
DATE=$(date +"%m-%d-%y")
BUILD_START=$(date +"%s")
ARCH=arm
CC=clang
CCOMP=arm-linux-gnueabi-
CONF=j4primelte_defconfig

# Export ARCH & SUBARCH
export ARCH=$ARCH
export SUBARCH=$ARCH

# Set Kernel & Host Name
# export VERSION=
export DEFCONFIG=$CONF

export LOCALVERSION=$VERSION

# Export Username & Machine Name
export KBUILD_BUILD_USER=Batu33TR
export KBUILD_BUILD_HOST=MicrosoftAzure

export PATH=$(pwd)/proton-clang/bin:$PATH
export CROSS_COMPILE=$(pwd)/proton-clang/bin/arm-linux-gnueabi-

# Make .config
make \
O=$OUT \
ARCH=$ARCH
CC=$CC \
HOSTCC=$CC \
CROSS_COMPILE=$CCOMP \
$CONF

# Compile Kernel
make \
O=$OUT \
ARCH=$ARCH \
CC=$CC \
HOSTCC=$CC \
CROSS_COMPILE=$CCOMP

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
    zip -r9 Teletubies-Clang-"${CODENAME}"-arm-"${DATE}".zip ./*
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
