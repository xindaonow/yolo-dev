FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Base system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      iptables ipset dnsutils ca-certificates \
      build-essential \
      python3 python3-pip python3-venv python3-dev \
      git curl wget jq \
    && rm -rf /var/lib/apt/lists/*

# Node.js LTS (NodeSource — includes npm)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Bun (system-wide at /usr/local/bin/bun)
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash

# uv (fast Python package manager, system-wide)
RUN curl -LsSf https://astral.sh/uv/install.sh | \
      env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh

# AI coding CLIs — Claude Code + OpenAI Codex (latest at build time).
# Self-update is off (DISABLE_AUTOUPDATER below), so they stay at the
# build-time version until the next ./build.sh. To freeze a specific version
# for reproducibility, append @x.y.z to each package.
RUN npm install -g \
        @anthropic-ai/claude-code \
        @openai/codex \
    && npm cache clean --force

# Opt-in egress firewall script + sudoers rule (no password for vscode user)
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh \
    && echo 'vscode ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh' \
       > /etc/sudoers.d/init-firewall \
    && chmod 0440 /etc/sudoers.d/init-firewall

# Stable image: turn off Claude Code self-update and telemetry
ENV DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    IS_SANDBOX=1

USER vscode

# Make sure user-level package manager dirs exist before volumes mount on top
RUN mkdir -p /home/vscode/.npm /home/vscode/.bun/install/cache \
             /home/vscode/.cache/uv /home/vscode/.cache/pip \
             /home/vscode/.claude /home/vscode/.codex

# Supply-chain hardening: minimum release age (dependency cooldown).
# Refuse to install package versions younger than 7 days — most malicious
# versions are detected and pulled within days, so a cooldown dodges them.
#   npm:  min-release-age in DAYS    (npm >= 11.10.0)
#   bun:  minimumReleaseAge in SECONDS (bun >= 1.3)  604800 = 7 days
RUN printf 'min-release-age=7\n' > /home/vscode/.npmrc \
    && printf '[install]\nminimumReleaseAge = 604800\n' > /home/vscode/.bunfig.toml
