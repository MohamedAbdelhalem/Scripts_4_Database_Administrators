dir=$1          #parameter1 means the directory /swap
siz=$2          #parameter2 means the swap file size = 1GB
swaparr=()
nofiles=()
siz=$((siz * 1024))
query=$(ls / | grep $dir)
exist=${#query}
if [[ $exist -gt 0 ]]; then
        swaparr=($(ls /$dir | grep swapfile))
        for ((c=0; $c<${#swaparr[@]}; c++)); do
                file=$(echo ${swaparr[$c]} | cut -d " " -f9-)
                nofiles=(${file:8:3})
        done
else
echo "do not exist"
fi

curr=$(($(echo "${nofiles[*]}" | sort -nr | head -n1) + 1))

dd if=/dev/zero of=/$dir/swapfile$curr bs=1M count=$siz
mkswap /$dir/swapfile$curr
chmod 600 /$dir/swapfile$curr
echo "/$dir/swapfile$curr         swap                    swap    defaults        0 0" >> /etc/fstab
swapon -a
swapon -s
free -h
