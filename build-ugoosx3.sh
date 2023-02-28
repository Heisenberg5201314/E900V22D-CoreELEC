#! /bin/sh
version="20.0-Nexus"
source_img_name="CoreELEC-Amlogic-ng.arm-${version}-Generic"
source_img_file="${source_img_name}.img.gz"
source_img_url="https://ghproxy.com/https://github.com/CoreELEC/CoreELEC/releases/download/${version}/${source_img_name}.img.gz"
target_img_prefix="CoreELEC-Amlogic-ng.arm-${version}"
target_img_name="${target_img_prefix}-UGOOSX3-$(date +%Y.%m.%d)"
mount_point="target"
common_files="common-files"
system_root="SYSTEM-root"
modules_load_path="${system_root}/usr/lib/modules-load.d"
systemd_path="${system_root}/usr/lib/systemd/system"
libreelec_path="${system_root}/usr/lib/libreelec"
config_path="${system_root}/usr/config"
firmware_path="${system_root}/usr/lib/kernel-overlays/base/lib/firmware"
kodi_userdata="${mount_point}/.kodi/userdata"

echo "Welcome to build CoreELEC for UGOOSX3!"
echo "Downloading CoreELEC-${version} generic image"
wget ${source_img_url} -O ${source_img_file} | exit 1
echo "Decompressing CoreELEC image"
gzip -d ${source_img_file} | exit 1

echo "Creating mount point"
mkdir -p ${mount_point}
echo "Mounting CoreELEC boot partition"
offset=$(($(fdisk -l -o start ${source_img_name}.img|grep -v "[a-zA-Z]"|grep -v "^$"|head -n1)*512))
sudo mount -o loop,offset=${offset} ${source_img_name}.img ${mount_point}

echo "Copying E900V22D DTB file"
sudo cp ${common_files}/ugoosx3.dtb ${mount_point}/dtb.img

echo "Decompressing SYSTEM image"
sudo unsquashfs -d ${system_root} ${mount_point}/SYSTEM

echo "Copying fs-resize script"
sudo cp ${common_files}/fs-resize ${libreelec_path}/fs-resize
sudo chown root:root ${libreelec_path}/fs-resize
sudo chmod 0775 ${libreelec_path}/fs-resize


echo "Copying hwdb files"
sudo cp ${common_files}/CMCC_Voice_Remote.hwdb ${config_path}/hwdb.d/CMCC_Voice_Remote.hwdb
sudo chown root:root ${config_path}/hwdb.d/CMCC_Voice_Remote.hwdb
sudo chmod 0644 ${config_path}/hwdb.d/CMCC_Voice_Remote.hwdb



echo "Copying remotewakeup files"
sudo cp ${common_files}/ugoosx3.remotewakeup ${config_path}/ugoosx3.remotewakeup
sudo chown root:root ${config_path}/ugoosx3.remotewakeup
sudo chmod 0644 ${config_path}/ugoosx3.remotewakeup


echo "Compressing SYSTEM image"
sudo mksquashfs ${system_root} SYSTEM -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 -b 524288 -no-xattrs
echo "Replacing SYSTEM image"
sudo rm ${mount_point}/SYSTEM.md5
sudo dd if=/dev/zero of=${mount_point}/SYSTEM
sudo sync
sudo rm ${mount_point}/SYSTEM
sudo mv SYSTEM ${mount_point}/SYSTEM
sudo md5sum ${mount_point}/SYSTEM > SYSTEM.md5
sudo mv SYSTEM.md5 target/SYSTEM.md5
sudo rm -rf ${system_root}

echo "Unmounting CoreELEC boot partition"
sudo umount -d ${mount_point}
echo "Mounting CoreELEC data partition"
offset=$(($(fdisk -l -o start ${source_img_name}.img|grep -v "[a-zA-Z]"|grep -v "^$"|head -n2|tail -n1)*512))
sudo mount -o loop,offset=${offset} ${source_img_name}.img ${mount_point}

echo "Creating keymaps directory for kodi"
sudo mkdir -p -m 0755 ${kodi_userdata}/keymaps
echo "Copying kodi config files"
sudo cp ${common_files}/backspace.xml ${kodi_userdata}/keymaps/backspace.xml
sudo chown root:root ${kodi_userdata}/keymaps/backspace.xml
sudo chmod 0644 ${kodi_userdata}/keymaps/backspace.xml


echo "Creating guisettings.xml for kodi"
echo "Copying kodi config files"
sudo cp ${common_files}/guisettings.xml ${kodi_userdata}/guisettings.xml
sudo chown root:root ${kodi_userdata}/guisettings.xml
sudo chmod 0644 ${kodi_userdata}/guisettings.xml

echo "Creating mediasources.xml for kodi"
echo "Copying kodi config files"
sudo cp ${common_files}/mediasources.xml ${kodi_userdata}/mediasources.xml
sudo chown root:root ${kodi_userdata}/mediasources.xml
sudo chmod 0644 ${kodi_userdata}/mediasources.xml

echo "Unmounting CoreELEC data partition"
sudo umount -d ${mount_point}
echo "Deleting mount point"
rm -rf ${mount_point}

echo "Rename image file"
mv ${source_img_name}.img ${target_img_name}.img
echo "Compressing CoreELEC image"
gzip ${target_img_name}.img
sha256sum ${target_img_name}.img.gz > ${target_img_name}.img.gz.sha256
