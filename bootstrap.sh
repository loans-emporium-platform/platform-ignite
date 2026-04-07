#!/usr/bin/env bash
# platform-ignite/bootstrap.sh — Minimal Sovereign Bridge (V15.5)
# ─────────────────────────────────────────────────────────────────
# This is a LEAN script. All confidential logic (UFW, Docker, Hardening)
# is now moved into the private 'vps-brain' repository.
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

# 1. Essential Tools
apt-get update -qq && apt-get install -y -qq curl jq unzip git > /dev/null

# 2. Bitwarden BWS Bridge
if ! command -v bws &>/dev/null; then
    curl -fsSL https://github.com/bitwarden/sdk/releases/download/bws-v1.0.0/bws-x86_64-unknown-linux-gnu-1.0.0.zip -o /tmp/bws.zip
    unzip -oq /tmp/bws.zip -d /usr/local/bin/ && chmod +x /usr/local/bin/bws
    rm /tmp/bws.zip
fi

# 3. Root of Trust (One-Time Ignition Handshake)
if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    if [[ "${1:-}" ]]; then
        BWS_ACCESS_TOKEN="$1"
    else
        read -sp "[PROMPT] Enter Ephemeral BWS Access Token: " BWS_ACCESS_TOKEN
        echo ""
    fi
fi
export BWS_ACCESS_TOKEN

# 4. Sovereign Pre-Flight (The Seed Pull)
echo "🔍 [PRE-FLIGHT] Pulling Sovereign Seeds from Bitwarden..."

# Fetch Critical Seeds (DB URL, Master Key, Git PAT)
DATABASE_URL=$(bws secret list | jq -r '.[] | select(.key == "DATABASE_URL") | .value')
MASTER_ENCRYPTION_KEY=$(bws secret list | jq -r '.[] | select(.key == "MASTER_ENCRYPTION_KEY") | .value')
BOOTSTRAP_PAT=$(bws secret list | jq -r '.[] | select(.key == "GIT_PAT") | .value')

if [[ -z "$DATABASE_URL" || -z "$MASTER_ENCRYPTION_KEY" || -z "$BOOTSTRAP_PAT" ]]; then
    echo "❌ FATAL: Sovereign Seeds missing from Bitwarden vault."
    exit 1
fi

# 5. Harden Local Environment (Seed Persistence)
CONFIG_DIR="/opt/platform/config"
mkdir -p "$CONFIG_DIR"
cat <<EOF > "$CONFIG_DIR/.env"
DATABASE_URL="$DATABASE_URL"
MASTER_ENCRYPTION_KEY="$MASTER_ENCRYPTION_KEY"
EOF
chmod 600 "$CONFIG_DIR/.env"
echo "✅ [PRE-FLIGHT] Seeds Hardened (chmod 600). Proceeding to Ingestion..."

# 6. Private Runtime Handover (Handshake)
INSTALL_DIR="/opt/platform"
mkdir -p "$INSTALL_DIR"
if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    git clone "https://x-access-token:${BOOTSTRAP_PAT}@github.com/loans-emporium-platform/vps-brain.git" "$INSTALL_DIR"
fi

# 7. Burn-After-Reading (Purge Ephemeral Secrets)
unset BOOTSTRAP_PAT
unset BWS_ACCESS_TOKEN
echo "🔥 [IGNITE] Ephemeral Secrets Purged from Memory. Stage 1 Complete."

# 8. Execute Final Setup (Stage 2)
cd "$INSTALL_DIR"
./setup.sh
