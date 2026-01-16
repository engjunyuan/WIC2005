FROM alpine:3.19

# Install FRRouting and SSH server for router simulation
RUN apk add --no-cache \
    frr \
    frr-openrc \
    vlan \
    iptables \
    strongswan \
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

# Enable IP forwarding
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# Load VLAN and netfilter modules (required for trunking, ACLs, NAT, IPSec)
RUN echo "8021q" > /etc/modules-load.d/networking.conf && \
    printf "%s\n" nf_conntrack nf_nat iptable_filter iptable_nat xfrm_user xfrm_algo esp4 > /etc/modules-load.d/netfilter.conf

# FRR daemons config
RUN mkdir -p /etc/frr && \
    echo -e "zebra=yes\nbgpd=yes\nospfd=yes\nripd=yes\nstaticrouted=yes" > /etc/frr/daemons && \
    chown -R frr:frr /etc/frr && \
    chmod 755 /etc/frr

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 179 2601 2605

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
