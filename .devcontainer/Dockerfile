FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    gnupg \
    lsb-release \
    ca-certificates \
    software-properties-common \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@10

# Install Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.5-stable.tar.xz \
    && tar -xf flutter_linux_3.44.5-stable.tar.xz -C /opt/ \
    && rm flutter_linux_3.44.5-stable.tar.xz \
    && flutter config --no-analytics \
    && flutter precache \
    && dart --disable-analytics

# Install .NET SDK 8.0
RUN wget -q https://dot.net/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet \
    && rm dotnet-install.sh \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# Install Docker CLI (for Docker-from-Docker)
RUN curl -fsSL https://get.docker.com | bash

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Accept Android licenses placeholder (will be mounted from host)
RUN mkdir -p /home/vscode/.android && touch /home/vscode/.android/repositories.cfg

# Clean up
RUN apt-get autoremove -y && apt-get clean

ENV DEBIAN_FRONTEND=dialog
