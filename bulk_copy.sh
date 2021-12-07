#sh bulk_copy.sh .py view ./ paython
#sh bulk_copy.sh .py copy ./ paython

search=$1
action=$2
copyfm=$3
copyto=$4
v=0
flagfm=0
flagto=0
searchex=$search
if [[ $search == *"."* ]]; then
        searchex=$(echo ${search:1:$((${#search} - 1))})
fi

list=($(ls -l | grep "$search" | grep "\<$searchex\>"))
no=$(ls -l | grep $search | grep "\<$searchex\>" | wc -l)

if [[ $(echo ${copyto:0:1}) != "/" ]]; then
        flagto=$((flagto + 1))
fi
if [[ $(echo ${copyto:$((${#copyto} - 1)):1}) != "/" ]]; then
        flagto=$((flagto + 2))
fi
if [[ $(echo ${copyto:0:2}) == "./" ]]; then
        flagto=$((flagto - 1))
fi

if [[ $(echo ${copyfm:0:1}) != "/" ]]; then
        flagfm=$((flagfm + 1))
fi
if [[ $(echo ${copyfm:$((${#copyfm} - 1)):1}) != "/" ]]; then
        flagfm=$((flagfm + 2))
fi
if [[ $(echo ${copyfm:0:2}) == "./" ]]; then
        flagfm=$((flagfm - 1))
fi

echo $flagto
echo $flagfm

if [[ $flagto == 1 ]]; then
        copyto=./$copyto
elif [[ $flagto == 2 ]]; then
        copyto=$copyto/
elif [[ $flagto == 3 ]]; then
        copyto=./$copyto/
fi

if [ $flagfm == 0 ] | [ $action == "view" ]; then
        for ((c=0; c < $no; c++)); do
                v=$(($(($(($c + 1)) * 9)) - 1))
                echo mv $copyfm${list[$v]} $copyto${list[$v]}
                #echo file ${list[$v]} transferred from $copyfm to $copyto successfully.
        done
elif [ $flagfm == 0 ] | [ $action == "copy" ]; then
        for ((c=0; c < $no; c++)); do
                v=$(($(($(($c + 1)) * 9)) - 1))
                mv $copyfm${list[$v]} $copyto${list[$v]}
                echo file ${list[$v]} transferred from $copyfm to $copyto successfully.
        done
else
        echo "Please add the source floder with right format /source/ or ./ for the current"
fi

