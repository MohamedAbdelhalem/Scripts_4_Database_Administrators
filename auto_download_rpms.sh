#you already have a curl from a website like curl postgresql.org/dowmload > ~/postgreSQL.repo.txt
#and you need to download all the rpms automatically 
#so you can use the below script :)

url=$1
postrpms=($(cat ~/postgreSQL.repo.txt | grep .rpm))
filesno=$(echo ${#postrpms[@]})
files=()
no=0
echo $filesno
for ((c=0; c< $filesno; c++)); do
        file=$(echo ${postrpms[$c]} | cut -d ">" -f1)
        file=${file:6:1000}
        if [[ ${file:0:1} != "-" && $file == *".rpm"* ]]; then
                file=$(echo ${file:0:$((${#file}-1))})
                echo $file
                files[$no]+=$file
                no=$((no + 1))
        fi
done
for ((u=0; u<$(echo ${#files[@]}); u++)); do
        curl -O $url${files[$u]}
done
