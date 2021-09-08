nofiles=($(ls -lh | wc -l))
nofiles=$(($nofiles - 1))
readarray repos < <(ls -l)
for((c=0; c<$nofiles+1; c++)); do
if [[ $c -gt 0 ]]; then
filename=$(echo ${repos[$c]})
file=$(echo $filename | cut -d':' -f2)
f=$(echo ${file:2:${#file}})
ex=$(echo "mv "$f $f.old)
$ex
fi
done
