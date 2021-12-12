vi /etc/ssh/sshd_config
systemctl restart sshd

vi /etc/profile
export PROXY_URL="http://10.10.62.35:8080/"
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"

source /etc/profile
env | grep proxy 
cd /etc/yum.repos.d/

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

subscription-manager refresh
yum clean all
yum repolist
yum install -y telnet
yum update -y

##remove and install perl or any packages
rpm -qa | grep perl > /tmp/pkgs
for i in `cat /tmp/pkgs`; do rpm -ev --nodeps $i; done
yum install --disablerepo=rhel-8-for-x86_64-appstream-eus-rpms -y perl
