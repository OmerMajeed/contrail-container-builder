ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-vpp-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME

RUN yum install -y vpp-lib vpp-devel vpp-plugins vpp-debuginfo vpp-selinux-policy vpp-api-python vpp-api-java vpp-api-lua vpp \
      dhclient NetworkManager contrail-vpp-agent haproxy libvirt-client \
      python-opencontrail-vrouter-netns python-contrail-vrouter-api && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    ldconfig

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-vpp-agent"]

ENV SERVICE_NAME=agent
LABEL net.juniper.contrail.service=$SERVICE_NAME
LABEL net.juniper.contrail.container.name=$CONTAINER_NAME
