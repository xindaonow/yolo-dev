#!/usr/bin/env bash
# Egress allowlist firewall — opt-in hardening for the dev container.
#
# Default-deny outbound traffic, except DNS, loopback, established
# connections, and a curated set of dev/AI domains.
#
# Run manually inside the container after first start:
#   sudo /usr/local/bin/init-firewall.sh
#
# Requires NET_ADMIN + NET_RAW capabilities (already set in devcontainer.json).
# Re-run after adding domains to the allowlist below.

set -euo pipefail
IFS=$'\n\t'

if [[ $EUID -ne 0 ]]; then
  echo "init-firewall.sh must run as root (use sudo)" >&2
  exit 1
fi

# Reset
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
ipset destroy allowed-domains 2>/dev/null || true

# Default deny
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Loopback
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT  -p tcp --sport 53 -j ACCEPT

# Established connections
iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

ipset create allowed-domains hash:net

DOMAINS=(
  # Anthropic / Claude Code
  api.anthropic.com
  console.anthropic.com
  statsig.anthropic.com
  sentry.io

  # OpenAI / Codex
  api.openai.com
  chatgpt.com
  auth.openai.com

  # Package registries
  registry.npmjs.org
  registry.yarnpkg.com
  pypi.org
  files.pythonhosted.org
  bun.sh
  jsr.io
  deno.land

  # GitHub
  github.com
  api.github.com
  raw.githubusercontent.com
  objects.githubusercontent.com
  codeload.github.com
  ghcr.io

  # Tool installers
  astral.sh

  # VS Code marketplace
  marketplace.visualstudio.com
  update.code.visualstudio.com
  vscode.download.prss.microsoft.com

  # HuggingFace
  huggingface.co
  cdn-lfs.huggingface.co
)

for domain in "${DOMAINS[@]}"; do
  ips=$(dig +short A "$domain" || true)
  while IFS= read -r ip; do
    [[ -z "$ip" ]] && continue
    [[ "$ip" =~ ^[0-9.]+$ ]] || continue
    ipset add allowed-domains "$ip" 2>/dev/null || true
  done <<< "$ips"
done

iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

echo "Firewall initialized. Allowlisted ${#DOMAINS[@]} domains."
echo "Re-run after editing the allowlist or if a CDN's IPs rotate."
