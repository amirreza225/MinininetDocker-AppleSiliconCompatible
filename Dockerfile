# Standalone Mininet Docker Container for SDN Development
FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update and install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-dev \
    curl \
    wget \
    git \
    net-tools \
    lsof \
    htop \
    iftop \
    tcpdump \
    iproute2 \
    iputils-ping \
    iperf \
    openvswitch-switch \
    openvswitch-common \
    sudo \
    nano \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies with eventlet version that has ALREADY_HANDLED
RUN pip3 install --no-cache-dir \
    eventlet==0.30.2 \
    ryu==4.34 \
    routes>=2.5.1 \
    webob>=1.8.7

# Manual Mininet Python 3 installation approach
# Install required system packages first
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    git \
    gcc \
    libc6-dev \
    python3-distutils \
    python3-setuptools \
    && rm -rf /var/lib/apt/lists/*

# Install Mininet Python modules and executables manually
RUN git clone https://github.com/mininet/mininet.git /tmp/mininet && \
    cd /tmp/mininet && \
    echo "Installing Mininet Python modules..." && \
    python3 setup.py install && \
    echo "Installing Mininet executables..." && \
    install bin/mn /usr/local/bin/ && \
    echo "Building mnexec manually..." && \
    cd /tmp/mininet && \
    gcc -Wall -Wextra -DVERSION='"2.3.1b4"' mnexec.c -o mnexec && \
    install mnexec /usr/local/bin/ && \
    echo "Installing other utilities..." && \
    install util/m /usr/local/bin/ && \
    echo "Mininet installation completed" && \
    rm -rf /tmp/mininet

# Install X11 support, xterm, and Wireshark for display forwarding on macOS
RUN echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections && \
    apt-get update && apt-get install -y \
    x11-apps \
    xterm \
    wireshark \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy startup script and examples
COPY start_services.sh /app/start_services.sh
COPY examples/ /app/examples/
RUN chmod +x /app/start_services.sh

# Create python symlink for compatibility with mn command
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set environment variables for Python3 Mininet compatibility
ENV PYTHONPATH="/usr/local/lib/python3.8/site-packages:/usr/lib/python3/dist-packages:/usr/local/lib/python3.8/dist-packages:/app"
ENV MININET_PATH="/usr/local/lib/python3.8/site-packages"

# Create a user for running mininet (optional, for security)
RUN useradd -m -s /bin/bash mininet && \
    echo "mininet ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -a -G wireshark mininet

# Expose common ports
EXPOSE 6653 8080 8000

# Default command starts services and bash
CMD ["/app/start_services.sh"]