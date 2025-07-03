# Use the specified Node.js base image
FROM node:20.19.3-bookworm-slim@sha256:f8f6771d949ff351c061de64ef9cbfbc5949015883fb3b016b34aca6d0e5b8cc

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/snap/bin:$PATH"
ENV TTYD_COMMAND=bash
ENV TTYD_AUTH_USER=""
ENV TTYD_AUTH_PASSWORD=""

# Install system dependencies and update package manager
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gettext-base \
    unzip \
    build-essential \
    cmake \
    git \
    libuv1-dev \
    libwebsockets-dev \
    libjson-c-dev \
    libssl-dev \
    zlib1g-dev \
    tmux \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd from pre-built binary (more reliable than building from source)
RUN curl -L https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Install Caddy
RUN curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update && \
    apt-get install -y caddy && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI via npm
RUN npm install -g @anthropic-ai/claude-code

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /usr/share/keyrings/helm.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y helm && \
    rm -rf /var/lib/apt/lists/*

# Install yq
RUN curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq


# Install overmind process manager
RUN curl -L https://github.com/DarthSim/overmind/releases/download/v2.5.1/overmind-v2.5.1-linux-amd64.gz -o overmind.gz && \
    gunzip overmind.gz && \
    chmod +x overmind && \
    mv overmind /usr/local/bin/

# Configure for Podman compatibility
RUN mkdir -p /var/lib/containers && \
    chmod 755 /var/lib/containers

# Set up proper user and working directory
RUN useradd -m -s /bin/bash agent && \
    usermod -aG sudo agent
USER agent
WORKDIR /home/agent

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose ports for ttyd and caddy
EXPOSE 7681 8080

# Copy Procfile, Caddyfile and startup script
COPY Procfile /home/agent/Procfile
COPY Caddyfile.simple /home/agent/Caddyfile.simple
COPY --chmod=755 start-ttyd.sh /home/agent/start-ttyd.sh

# Entry point - TLS-enabled ttyd with runtime certificate generation
CMD ["/home/agent/start-ttyd.sh"]