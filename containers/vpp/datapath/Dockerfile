ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM centos:7.5.1804

ARG CONTAINER_NAME

RUN yum install -y iproute net-tools pciutils libffi-devel boost-thread-1.53.0-27.el7 python-setuptools numactl-libs \
    libselinux-utils policycoreutils policycoreutils-python selinux-policy-base selinux-policy-targeted \
    vpp-lib vpp-devel vpp-plugins vpp-debuginfo vpp-selinux-policy vpp-api-python vpp-api-java vpp-api-lua vpp \
    contrail-vrouter-dpdk contrail-vrouter-dpdk-init && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    ldconfig

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/vpp"]

ENV SERVICE_NAME=vpp-datapath
LABEL net.juniper.contrail.service=agent-dpdk
LABEL net.juniper.contrail.container.name=$CONTAINER_NAME
