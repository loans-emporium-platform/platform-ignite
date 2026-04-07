#!/usr/bin/env bash
# platform-ignite/bootstrap.sh — Minimal Sovereign Bridge (V15.5)
# ─────────────────────────────────────────────────────────────────
# This is a LEAN script. All confidential logic (UFW, Docker, Hardening)
# is now moved into the private 'platform-core' repository.
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

# 3. Root of Trust (Handshake)
if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    read -sp "[PROMPT] Enter BWS Access Token: " BWS_ACCESS_TOKEN
    echo ""
fi
export BWS_ACCESS_TOKEN

# 4. Sovereign Pre-Flight (The Minimum Trio)
echo "🔍 [PRE-FLIGHT] Verifying Bitwarden Seed Connectivity..."

# Fetch Secret Manifest for Validation
BWS_SECRETS=$(bws secret list | jq -r '.[] | .key')

verify_secret() {
    if ! echo "$BWS_SECRETS" | grep -qx "$1"; then
        echo "❌ FATAL: Missing Critical Seed in BWS: $1"
        exit 1
    fi
}

# Verify the Minimum Trio (Seed PAT, DB URL, Master Key)
verify_secret "GIT_PAT"
verify_secret "DATABASE_URL"
verify_secret "MASTER_ENCRYPTION_KEY"

# Extract Bootstrap PAT for One-Time Clone
BOOTSTRAP_PAT=$(bws secret list | jq -r '.[] | select(.key == "GIT_PAT") | .value')
echo "✅ [PRE-FLIGHT] Seeds Verified. Proceeding to Platform Ingestion..."

# 5. Private Core Handover (Handshake)
INSTALL_DIR="/opt/platform"
mkdir -p "$INSTALL_DIR"
if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    git clone "https://x-access-token:${BOOTSTRAP_PAT}@github.com/Loans-Emporium/platform-core.git" "$INSTALL_DIR"
fi

# 6. Burn-After-Reading (Purge Ingestion Keys)
unset BOOTSTRAP_PAT
echo "🔥 [IGNITE] Bootstrap PAT purged from environment."

# 7. Execute Confidential Setup (Stage 2)
cd "$INSTALL_DIR"
./setup.sh --bws-token "$BWS_ACCESS_TOKEN"

# Final Purge of the Ignition Key (Bitwarden)
unset BWS_ACCESS_TOKEN
echo "🔥 [IGNITE] BWS token purged. Stage 1 Complete."
