# Use Ubuntu as the base image
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get install -y \
    bash \
    bash-completion \
    coreutils \
    netcat-openbsd \
    curl \
    wget \
    openssl \
    jq \
    ca-certificates \
    python3 \
    python3-pip \
    git \
    net-tools \
    openssh-client \
    iperf \
    nmap \
    dnsutils \
    iputils-ping \
    tcpdump \
    ngrep \
    traceroute \
    iproute2 \
    tcptraceroute \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /tools

# Default command
CMD ["bash"]
