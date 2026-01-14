FROM alpine:3.19

# Install everything needed for routers AND switches
RUN apk add --no-cache \
    frr \
    frr-openrc \
    bridge-utils \
    vlan \
    openssh \
    iproute2 \
    tcpdump \
    bash \
    nano \
    curl \
    iperf3 \
    && mkdir -p /run/sshd

# Configure SSH
RUN echo "root:netdev123" | chpasswd && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    ssh-keygen -A

# Enable IP forwarding and load VLAN module
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf && \
    echo "8021q" > /etc/modules-load.d/networking.conf

# FRR daemons config (for routers)
RUN echo -e "zebra=yes\nbgpd=yes\nospfd=yes\nripd=yes\nstaticrouted=yes" > /etc/frr/daemons

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 179 2601 2605

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
