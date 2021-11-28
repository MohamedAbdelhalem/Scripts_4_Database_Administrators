#you already have a curl from a website like curl postgresql.org/dowmload > ~/postgreSQL.repo.txt
#and you need to download all the rpms automatically 
#so you can use the below script :)
#examples
#
#sh ~/downloadPostgreSQLFiles.sh download sqlite https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-x86_64/
#sh ~/downloadPostgreSQLFiles.sh download all https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-x86_64/
#sh ~/downloadPostgreSQLFiles.sh view sqlite https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-x86_64/
#sh ~/downloadPostgreSQLFiles.sh view all https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-8-x86_64/

action=$1               #view or download
search=$2               #all or a name in the packages like sqlite or python3
url=$3                  #the original URL https://download.postgresql.org/pub/repos/yum/12/redhat 
                        #that you already curl of into the txt file ~/postgreSQL.repo.txt 

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
        if [[ $search == "all" ]]; then
                if [[ $action == "view" ]]; then
                        echo curl -O $url${files[$u]}
                elif [[ $action == "download" ]]; then
                        curl -O $url${files[$u]}
                fi
        else
                if [[ $action == "view" && $(echo ${files[$u]}) == *"$search"* ]]; then
                        echo curl -O $url${files[$u]}
                elif [[ $action == "download" && $(echo ${files[$u]}) == *"$search"* ]]; then
                        curl -O $url${files[$u]}
                fi
        fi
done
