#!/bin/sh
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export INITRAMFS_SOURCE=`readlink -f ..`/Ramdisks/Slimmed_JB_MR2-3.4
export CONFIG_AOSP_BUILD=y
export PACKAGEDIR=$PARENT_DIR/Packages/Slimmed_JB_MR2-3.4-ATT
#Enable FIPS mode
export USE_SEC_FIPS_MODE=true
export ARCH=arm
# export CROSS_COMPILE=$PARENT_DIR/linaro4.5/bin/arm-eabi-
# export CROSS_COMPILE=/home/ktoonsez/kernel/siyah/arm-2011.03/bin/arm-none-eabi-
# export CROSS_COMPILE=/home/ktoonsez/android/system/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
# export CROSS_COMPILE=/home/ktoonsez/aokp4.2/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-
export CROSS_COMPILE=/home/jason/Android/linaro-4.7/bin/arm-eabi-

echo "Remove old Package Files"
rm -rf $PACKAGEDIR/*

echo "Setup Package Directory"
mkdir -p $PACKAGEDIR/system/app
mkdir -p $PACKAGEDIR/system/lib/modules
mkdir -p $PACKAGEDIR/system/etc/init.d

echo "Create initramfs dir"
mkdir -p $INITRAMFS_DEST

echo "Remove old initramfs dir"
rm -rf $INITRAMFS_DEST/*

echo "Copy new initramfs dir"
cp -R $INITRAMFS_SOURCE/* $INITRAMFS_DEST

echo "chmod initramfs dir"
chmod -R g-w $INITRAMFS_DEST/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print)
rm -rf $(find $INITRAMFS_DEST -name .git -print)

echo "Remove old zImage"
rm $PACKAGEDIR/zImage
rm arch/arm/boot/zImage

echo "Make the kernel"
# make KT747_d2att_defconfig
make VARIANT_DEFCONFIG=cyanogen_d2att_defconfig SELINUX_DEFCONFIG=m2selinux_defconfig Slimmed_d2_defconfig

HOST_CHECK=`uname -n`
if [ $HOST_CHECK = 'jason-pc' ]; then
	echo "Jason-PC! 8"
	make -j8
else
	echo "Others! - " + $HOST_CHECK
	make -j12
fi;

echo "Copy modules to Package"
cp -a $(find . -name *.ko -print |grep -v initramfs) $PACKAGEDIR/system/lib/modules/
cp 00post-init.sh $PACKAGEDIR/system/etc/init.d/00post-init.sh
cp enable-oc.sh $PACKAGEDIR/system/etc/init.d/enable-oc.sh
cp /home/jason/Android/kernel/com.ktoonsez.KTweaker.apk $PACKAGEDIR/system/app/com.ktoonsez.KTweaker.apk
#cp ../Ramdisks/libsqlite.so $PACKAGEDIR/system/lib/libsqlite.so

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo "Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "Make boot.img"
	./mkbootfs $INITRAMFS_DEST | gzip > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline 'console = null androidboot.hardware=qcom user_debug=31 zcache' --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdiskaddr 0x81500000 --output $PACKAGEDIR/boot.img 
	export curdate=`date "+%m-%d-%Y"`
	cd $PACKAGEDIR
	cp -R ../META-INF .
	rm ramdisk.gz
	rm zImage
	rm ../Slimmed-JB-MR2-3.4-ATT*.zip
	zip -r ../Slimmed-JB-MR2-3.4-ATT-$curdate.zip .
	cd $KERNELDIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;
