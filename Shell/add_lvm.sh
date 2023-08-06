disk=$1
part_no=$2
vg=$3
lv=$4
mount_point=$5
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo $part_no # Partition number
echo   # First sector (Accept default: 1)
echo   # Last sector (Accept default: varies)
echo t # Write changes
echo 8e # Write changes
echo w # Write changes
) | fdisk /dev/$disk

#wc=$(lsblk | grep $disk | wc)
#part=$(echo $wc| cut -d' ' -f 1) - 1
pvcreate /dev/$disk$part_no
vgcreate $vg /dev/$disk$part_no
lvcreate --name $lv -l 100%FREE $vg
mkfs.ext4 /dev/$vg/$lv
mkdir -p $mount_point
mount /dev/$vg/$lv $mount_point
echo /dev/$vg/$lv  $mount_point ext4 defaults 0 0 >> /etc/fstab
