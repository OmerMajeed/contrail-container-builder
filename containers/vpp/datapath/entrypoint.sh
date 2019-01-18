#!/bin/bash

/sbin/modprobe uio_pci_generic
/bin/rm -f /dev/shm/db /dev/shm/global_vm /dev/shm/vpe-api
cmd="$@ -c /etc/vpp/startup.conf"
$cmd &
vpp_datapath_process=$!

ip tuntap add name vhost0 mode tap
ifconfig vhost0 192.168.17.10/24

ip tuntap add name vpp0 mode tap
ifconfig vpp0 192.168.17.4/24

sleep 10
vppctl tap connect vpp0
vppctl set interface state tapcli-0 up
vppctl set interface l2 bridge tapcli-0 9000
vppctl set interface state GigabitEthernet2/0/1 up
vppctl set interface l2 bridge GigabitEthernet2/0/1 9000
vppctl create loopback interface mac de:ad:00:00:00:28 instance 9000
vppctl set interface state loop9000 up
vppctl set interface l2 bridge loop9000 9000 bvi
vppctl set interface ip address loop9000 192.168.17.10/24
vppctl set bridge-domain arp term 9000
vppctl set bridge-domain arp entry 9000 192.168.17.10 de:ad:00:00:00:28

# wait for vpp-agent to start
#waiting_agent=true
#while $waiting_agent
#do
#    vpp_agent=`ps ax | grep contrail-vpp | grep "\-\-config_file" | awk '{ prinnt $1 }'`
#    sleep 5
#    if [ "$vpp_agent" != "" ]
#    then
#        waiting_agent=false
#    fi
#done
#wait $vpp_agent

wait $vpp_datapath_process
