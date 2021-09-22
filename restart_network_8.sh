neck=$(ip a | grep 2:)
nname=${neck:3:6}
ifdown $nname; ifup $nname
ip a | grep $nname
