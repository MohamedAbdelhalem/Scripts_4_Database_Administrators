dir=$1
siz=$2
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

dd if=/dev/zero of=/swap/swapfile$curr bs=1M count=$siz
mkswap /swap/swapfile$curr
chmod 600 /swap/swapfile$curr
echo "/swap/swapfile$curr         swap                    swap    defaults        0 0" >> /etc/fstab
swapon -a
swapon -s
free -h
