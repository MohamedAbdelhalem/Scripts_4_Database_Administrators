disk=$1
disk_number=$2
vg=$3
lv=$4
mount_point=$5

mount -a $mount_point
lvchange -an /dev/$vg
lvremove /dev/$vg
vgremove $vg
pvremove /dev/$disk$disk_number
(
echo d
echo w
) | fdisk /dev/$disk
