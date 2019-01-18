ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-vpp-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME

RUN yum install -y vpp-lib vpp-devel vpp-plugins vpp-debuginfo vpp-selinux-policy vpp-api-python vpp-api-java vpp-api-lua vpp \
    contrail-vrouter-dpdk contrail-vrouter-dpdk-init && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    ldconfig

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/vpp"]

ENV SERVICE_NAME=agent-dpdk
LABEL net.juniper.contrail.service=agent-dpdk
LABEL net.juniper.contrail.container.name=$CONTAINER_NAME
