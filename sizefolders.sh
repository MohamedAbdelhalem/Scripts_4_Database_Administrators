nofolders=($(ls -lh | grep "^d" | wc -l))
readarray folders < <(ls -l | grep "^d")
for((c=0; c<$nofolders; c++)); do
    foldername=$(echo "${folders[$c]}")
    f=${foldername:53:100}
    siz="./"$f" size "
    len=${#siz}
    len=$((54 - $len))
    char=$(printf "#%.0s" $(seq $len))
    if [[ "$f" = *" "* ]]; then
        d=$(du -ch ./Tibco' 'SRC | grep total)
            echo "./"$f" size "$char" "$d
    else
            d=$(du -ch ./$f | grep total)
            echo "./"$f" size "$char" "$d
    fi
done
