#!/bin/bash
# Kernel Repack Script by Hybridmax (hybridmax95@gmail.com)

clear
echo
echo

# vars
export KERNEL_DIR=$(pwd)
export CURDATE=`date "+%Y.%m.%d"`
export IMAGE_DIR=arch/arm64/boot
export BUILD_IMG=build_image
export DTS=arch/arm64/boot/dts
export ZIP_DIR=zip_files
export MODULES_DIR=build_image/zip_files/system/lib/modules
export DEVELOPER="Mystery"
export DEVICE="S6-Edge"
export VERSION_NUMBER="$(cat $KERNEL_DIR/version)"
export HYBRIDVER="$DEVELOPER-Kernel-$DEVICE-$VERSION_NUMBER-($CURDATE)"
export KERNEL_NAME="$HYBRIDVER"

#########################################################################################
# Check Image
if [ -f "arch/arm64/boot/Image" ]; then
	clear
	echo "............................................."
	echo "Repacking Boot.img, wait"
	echo "............................................."
	echo " "
	sleep 3

else
	echo "............................................."
	echo "Exiting cause no Image was found!"
	echo "............................................."
	sleep 3
	exit
fi
#########################################################################################

# Copy Modules & Image

echo "Copy Modules............................"
echo " "
find -name '*.ko' -exec cp -av {} $MODULES_DIR \;
#${CROSS_COMPILE}strip --strip-unneeded $MODULES_DIR/*

echo "Copy Image.............................."
echo " "
cp $IMAGE_DIR/Image $BUILD_IMG/G925F/Image
#########################################################################################
# DT.IMG Generation

#clear
#echo "Make DT.img............................"
#echo " "
#./tools/dtbtool -o $BUILD_IMG/G925F/dt.img -s 2048 -p ./scripts/dtc/ $DTS/ | sleep 1

#########################################################################################
# Calculate DTS size

#du -k "$BUILD_IMG/G925F/dt.img" | cut -f1 >sizT
#sizT=$(head -n 1 sizT)
#rm -rf sizT
#echo "dt.img: $sizT Kb"
#echo " "

#########################################################################################
# Ramdisk Generation

echo "Make Ramdisk............................"
echo " "
cd $BUILD_IMG
mkdir -p ramfs_tmp
cp -a G925F/ramdisk/* ramfs_tmp
cp ramdisk_fix_permissions.sh ramfs_tmp/ramdisk_fix_permissions.sh
chmod 0777 ramfs_tmp/ramdisk_fix_permissions.sh
cd ramfs_tmp
./ramdisk_fix_permissions.sh
rm -f ramdisk_fix_permissions.sh

# ADB Fix
if [ -f "../G925F/patch/adbd_5.1.1" ]; then

cp -r sbin/adbd sbin/adbd.bak
cp -r ../G925F/patch/adbd_5.1.1 sbin/adbd

fi

find . | fakeroot cpio -H newc -o | lzop -9 > ../ramdisk.cpio.lzo

cd ..

mv ramdisk.cpio.lzo G925F

rm -r ramfs_tmp

#########################################################################################
# Boot.img Generation

echo "Make boot.img..........................."
echo " "
cd G925F
./../mkbootimg --kernel Image --ramdisk ramdisk.cpio.lzo --dt dt.img --base 0x10000000 --pagesize 2048 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --second_offset 0x00f00000 -o boot.img
echo -n "SEANDROIDENFORCE" >> boot.img
# copy the final boot.img to output directory ready for zipping
cp boot.img ../$ZIP_DIR/boot.img

#########################################################################################
# Generate Odin Flashable Kernel

#echo "Make tar.md5..........................."
#echo " "
#tar -H ustar -cvf $KERNEL_NAME.tar boot.img
#md5sum -t $KERNEL_NAME.tar >> $KERNEL_NAME.tar
#mv $KERNEL_NAME.tar output_kernel

#########################################################################################
# ZIP Generation

echo "Make ZIP................................"
echo " "
cd ../$ZIP_DIR
zip -r $KERNEL_NAME.zip *
mv $KERNEL_NAME.zip ../output_kernel

#########################################################################################
# Cleaning Up

cd ../..
echo "Make Clean.............................."
echo " "
rm -rf $BUILD_IMG/G925F/Image
rm -rf $BUILD_IMG/G925F/kernel
rm -rf $BUILD_IMG/G925F/ramdisk.cpio.*
rm -rf $BUILD_IMG/G925F/boot.img
#rm -rf $BUILD_IMG/G925F/dt.img
rm -rf $BUILD_IMG/boot.img
rm -rf $BUILD_IMG/ramdisk-cpio.*
rm -rf $BUILD_IMG/zip_files/boot.img
rm -rf $BUILD_IMG/zip_files/hybridmax/boot.img
rm -rf $BUILD_IMG/zip_files/system/lib/modules/*
echo "Done, $KERNEL_NAME.zip is ready!"
echo " "
