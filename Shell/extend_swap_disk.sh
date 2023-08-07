disk=sdc
s=$(ls /dev/mapper -l | grep swap)
swap=$(echo $s | cut -d ' '  -f9)
swap_vg=$(echo $(lvs | grep swap) | cut -d' ' -f2)
swapoff -v /dev/mapper/$swap

pvcreate /dev/$disk
vgextend ol /dev/$disk
vgchange -ay
lvextend -l +100%free /dev/$swap_vg/swap 
swapon -va
