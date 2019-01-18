#!/bin/bash

set -ex
mkdir -p /opt/plugin/bin
cp /opt/contrail/bin/vrouter-port-control /opt/plugin/bin/
cp /opt/contrail/bin/vrouter-port-control /usr/bin/


# linux distro here always centos for now
src_path='/usr/lib/python2.7/site-packages'

mkdir -p /opt/plugin/site-packages
for module in vif_plug_vrouter nova_contrail_vif ; do
  for item in `ls -d $src_path/${module}*` ; do
    cp -r $item /opt/plugin/site-packages/
  done
done
