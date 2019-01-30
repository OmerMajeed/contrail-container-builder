#!/bin/bash

source /common.sh
source /agent-functions.sh

echo "INFO: dpdk started"

function trap_dpdk_agent_quit() {
    term_process $dpdk_agent_process
    if [ -n "$pci_address" ] ; then
        restore_phys_int_dpdk "$pci_address"
    else
        echo "WARNING: PCIs list is empty, nothing to rebind to initial net driver"
    fi
    cleanup_vrouter_agent_files
}

function trap_dpdk_agent_term() {
    term_process $dpdk_agent_process
    if [ -n "$pci_address" ] ; then
        restore_phys_int_dpdk "$pci_address"
    else
        echo "WARNING: PCIs list is empty, nothing to rebind to initial net driver"
    fi
    remove_vhost0
    remove_vpp0
    restart_vpp_agent
}

# Clean up files and vhost0, when SIGQUIT signal by clean-up.sh
trap 'trap_dpdk_agent_quit' SIGQUIT

# Terminate process only.
# When a container/pod restarts it sends TERM and KILL signal.
# Every time container restarts we dont want to reset data plane
trap 'trap_dpdk_agent_term' SIGTERM SIGINT

pre_start_init

# remove rte configuration file (for case if vRouter has crashed)
rm -f '/run/.rte_config'

ensure_hugepages $HUGE_PAGES_DIR

set_ctl vm.nr_hugepages ${HUGE_PAGES}
set_ctl vm.max_map_count 128960
set_ctl net.ipv4.tcp_keepalive_time 5
set_ctl net.ipv4.tcp_keepalive_probes 5
set_ctl net.ipv4.tcp_keepalive_intvl 1
set_ctl net.core.wmem_max 9160000

if [ -n "${DPDK_UIO_DRIVER}" ]; then
    load_kernel_module uio
    load_kernel_module "$DPDK_UIO_DRIVER"
fi

# multiple kthreads for port monitoring
if ! load_kernel_module rte_kni kthread_mode=multiple ; then
    echo "WARNING: rte_ini kernel module is unavailable. Please install/insert it for Ubuntu 14.04 manually."
fi

if ! read_and_save_dpdk_params ; then
    echo "FATAL: failed to read data from NIC for DPDK mode... exiting"
    exit -1
fi

function assert_file() {
    local file=$1
    if [[ ! -f "$file" ]] ; then
        echo "ERROR: there is no file $file"
        exit -1
    fi
}

binding_data_dir='/var/run/vrouter'
assert_file "$binding_data_dir/nic"
phys_int=`cat "$binding_data_dir/nic"`
assert_file "$binding_data_dir/${phys_int}_mac"
phys_int_mac=`cat "$binding_data_dir/${phys_int}_mac"`
assert_file "$binding_data_dir/${phys_int}_pci"
pci_address=`cat "$binding_data_dir/${phys_int}_pci"`
echo "this file is required by nova_compute" > $binding_data_dir/dpdk_netlink
echo "INFO: Physical interface: $phys_int, mac=$phys_int_mac, pci=$pci_address"

addrs=$(get_addrs_for_nic $phys_int)

# base command
vpp_cmd="$@ -c /etc/vpp/startup.conf"

chmod 777 /var/run/vrouter

if [ -n "${DPDK_UIO_DRIVER}" ]; then
    if ! bind_devs_to_driver "$DPDK_UIO_DRIVER" "${pci_address//,/ }" ; then
        echo "FATAL: failed to bind $pci_address to the driver ${DPDK_UIO_DRIVER}... exiting"
        exit -1
    fi
fi

echo "INFO: start '$vpp_cmd'"
/bin/rm -f /dev/shm/db /dev/shm/global_vm /dev/shm/vpe-api
$vpp_cmd &
dpdk_agent_process=$!

ip tuntap add name vpp0 mode tap
ifconfig vpp0 $addrs/24
echo "created vpp0 with IP : $addrs"

loop_mac=$(echo de:ad:00:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10])

sleep 7

vppctl tap connect vpp0
vppctl set interface state tapcli-0 up
vppctl set interface l2 bridge tapcli-0 9000
vppctl set interface state GigabitEthernet2/0/1 up
vppctl set interface l2 bridge GigabitEthernet2/0/1 9000
vppctl create loopback interface mac $loop_mac instance 9000
vppctl set interface state loop9000 up
vppctl set interface l2 bridge loop9000 9000 bvi
vppctl set interface ip address loop9000 $VPP_CONTROL_ADDR/24
vppctl set bridge-domain arp term 9000
vppctl set bridge-domain arp entry 9000 $VPP_CONTROL_ADDR $loop_mac

export CONTRAIL_DPDK_CONTAINER_CONTEXT='true'
for i in {1..3} ; do
    echo "INFO: init vhost0... $i"
    init_vhost0 && break
    if (( i == 3 )) ; then
        echo "ERROR: failed to init vhost0.. exit"
        term_process $dpdk_agent_process
        exit -1
    fi
    sleep 3
done

wait $dpdk_agent_process
