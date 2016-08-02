#!/bin/bash

export ARCH=arm64
export CROSS_COMPILE=/home/hybridmax/android/toolchains/arm64/uber-aarch64_6.x/bin/aarch64-linux-android-

make ARCH=arm64 exynos7420-zeroflte_defconfig
make ARCH=arm64
