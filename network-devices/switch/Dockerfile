FROM alpine:3.19

# Install bridge-utils, vlan support, and SSH for switch simulation
RUN apk add --no-cache \
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

# Load 8021q module for VLANs
RUN echo "8021q" > /etc/modules-load.d/networking.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
