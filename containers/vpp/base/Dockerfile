ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}

RUN yum install -y libffi-devel libselinux-utils policycoreutils policycoreutils-python selinux-policy-base selinux-policy-targeted initscripts ethtool pciutils sudo contrail-vrouter-utils && \
    ldconfig

COPY *.sh ifup-* ifdown-* network-functions-vrouter* /

ENV NODE_TYPE=vrouter
LABEL net.juniper.contrail.pod=$NODE_TYPE
CMD ["/usr/bin/tail","-f","/dev/null"]
