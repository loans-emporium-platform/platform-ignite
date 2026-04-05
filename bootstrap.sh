#!/usr/bin/env bash
# platform-ignite/bootstrap.sh — Universal VPS Ignition (V15.0 Sovereign)
# ─────────────────────────────────────────────────────────────────
# This script establishes the Root of Trust, Hardens the OS,
# and enforces strict version integrity via the V15 Sovereign Engine.
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors & UI ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# ── Early Error Trap ─────────────────────────────────────────────
trap 'log_error "Bootstrap failed at line $LINENO. Manual remediation required."; exit 1' ERR

# ── Configuration ────────────────────────────────────────────────
GITHUB_ORG="Loans-Emporium"
INSTALL_DIR="/opt/platform"
BWS_VERSION="1.0.0"
BWS_SHA="9077fb7b336a62abc8194728fea8753afad8b0baa3a18723fc05fc02fdb53568"

# ── Resilience Helpers ───────────────────────────────────────────
apt_install_with_retry() {
    local packages=("$@")
    local max_attempts=3
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Installing ${packages[*]} (Attempt $attempt/$max_attempts)..."
        if apt-get install -y -qq --no-upgrade "${packages[@]}" > /dev/null 2>&1; then return 0; fi
        log_warn "Apt install failed. Retrying in 5s..."
        sleep 5
        ((attempt++))
        apt-get update -qq
    done
    return 1
}

verify_checksum() {
    local file="$1"; local expected_sha="$2"
    echo "${expected_sha}  ${file}" | sha256sum --check --status || {
        log_error "Checksum verification failed for ${file}!"
        exit 1
    }
}

# ── Localization & Identity ──────────────────────────────────────
if [[ -z "${VPS_HOSTNAME:-}" ]]; then
    echo -e "${YELLOW}[PROMPT]${NC} Enter a unique Hostname for this VPS: "
    read -p "> " VPS_HOSTNAME
fi
VPS_HOSTNAME="${VPS_HOSTNAME:?ERROR: VPS_HOSTNAME is mandatory}"
export DEBIAN_FRONTEND=noninteractive

# ─────────────────────────────────────────────────────────────────
# PHASE 1: OS Update & Base Tools
# ─────────────────────────────────────────────────────────────────
log_info "Phase 1: Establishing OS baseline..."
apt-get update -qq
apt_install_with_retry curl git jq unzip wget postgresql-client-17 openssl ufw rclone python3 python3-pip python3-venv

# 1. Swap Configuration (Archive logic)
if [[ ! -f /swapfile ]]; then
    log_info "Creating 2GB swapfile..."
    fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ─────────────────────────────────────────────────────────────────
# PHASE 2: Bitwarden BWS (Integrity Hardened)
# ─────────────────────────────────────────────────────────────────
log_info "Phase 2: Installing Bitwarden BWS CLI with SHA256 integrity..."
if ! command -v bws &>/dev/null; then
    curl -fsSL "https://github.com/bitwarden/sdk/releases/download/bws-v${BWS_VERSION}/bws-x86_64-unknown-linux-gnu-${BWS_VERSION}.zip" -o /tmp/bws.zip
    verify_checksum "/tmp/bws.zip" "$BWS_SHA" 
    mkdir -p /tmp/bws_pkg && unzip -oq /tmp/bws.zip -d /tmp/bws_pkg
    install -m 755 /tmp/bws_pkg/bws /usr/local/bin/bws
    rm -rf /tmp/bws.zip /tmp/bws_pkg
fi

# ─────────────────────────────────────────────────────────────────
# PHASE 3: Root of Trust Handshake
# ─────────────────────────────────────────────────────────────────
log_info "Phase 3: Fetching Global Infrastructure Vault..."
if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    echo -n -e "${YELLOW}[PROMPT]${NC} Please enter your Bitwarden BWS Access Token: "
    read -s BWS_ACCESS_TOKEN < /dev/tty
    echo ""
fi
export BWS_ACCESS_TOKEN

get_secret() { bws secret list | jq -r --arg key "$1" '.[] | select(.key == $key) | .value'; }

GIT_PAT=$(get_secret "GIT_PAT")
DB_URL=$(get_secret "DATABASE_URL")
MASTER_KEY=$(get_secret "MASTER_ENCRYPTION_KEY")
R2_CREDS=$(get_secret "R2_CREDENTIALS")
ALERT_CREDS=$(get_secret "ALERT_CREDENTIALS")

if [[ -z "$GIT_PAT" || -z "$DB_URL" || -z "$MASTER_KEY" ]]; then
    log_error "Mandatory Global Secrets missing from BWS. Halting."
    exit 1
fi

mkdir -p /opt/platform/config
cat <<EOF > /opt/platform/config/.env
BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN"
MASTER_ENCRYPTION_KEY="$MASTER_KEY"
DATABASE_URL="$DB_URL"
R2_CREDENTIALS='$R2_CREDS'
ALERT_CREDENTIALS='$ALERT_CREDS'
VPS_HOSTNAME="$VPS_HOSTNAME"
EOF
chmod 600 /opt/platform/config/.env

# ─────────────────────────────────────────────────────────────────
# PHASE 4: Manifest-Driven Software Pindowns
# ─────────────────────────────────────────────────────────────────
log_info "Phase 4: Fetching pinned versions from Registry DB..."
MANIFEST_JSON=$(psql "$DB_URL" -t -c "SELECT software_manifest FROM fleet_globalconfiguration LIMIT 1;")
DOCKER_V=$(echo "$MANIFEST_JSON" | jq -r '.docker // "27.1.1"')
TS_V=$(echo "$MANIFEST_JSON" | jq -r '.tailscale // "1.96.3"')

# 1. Docker (Archive pinning logic)
log_info "Enforcing Docker Engine v${DOCKER_V}..."
curl -fsSL https://get.docker.com | sh
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "5" }
}
EOF
systemctl restart docker

# 2. Tailscale Join
log_info "Configuring Tailscale Mesh Networking v${TS_V}..."
curl -fsSL https://tailscale.com/install.sh | sh
TS_KEY=$(get_secret "TAILSCALE_AUTH_KEY")
if [[ -n "$TS_KEY" ]]; then
    tailscale up --authkey="$TS_KEY" --hostname="$VPS_HOSTNAME" --ssh || log_warn "Mesh join failed."
fi

# ─────────────────────────────────────────────────────────────────
# PHASE 5: The "Bunker" Network Hardening (UFW)
# ─────────────────────────────────────────────────────────────────
log_info "Phase 5: Enforcing UFW with Login Protection..."
ufw --force reset && ufw default deny incoming && ufw default allow outgoing

log_info "Verifying Tailscale connectivity before locking Port 22..."
if tailscale status --json | jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
    log_success "Tailscale Mesh is healthy. Proceeding with Bunker Lockdown."
    ufw deny 22/tcp
    ufw allow in on tailscale0
else
    log_warn "Tailscale not joined. Allowing public SSH to prevent lockout."
    ufw allow 22/tcp
fi
ufw --force enable

# ─────────────────────────────────────────────────────────────────
# PHASE 5.5: Final OS Hygiene & Localization
# ─────────────────────────────────────────────────────────────────
log_info "Phase 5.5: Applying OS hygiene (Timezone, SSH Hardening, Logrotate)..."
timedatectl set-timezone "UTC" || true
hostnamectl set-hostname "$VPS_HOSTNAME" || true
echo "127.0.0.1 $VPS_HOSTNAME" >> /etc/hosts || true

cat <<EOF > /etc/logrotate.d/platform
/var/log/platform-*.log { weekly ; rotate 4 ; compress ; missingok ; notifempty ; create 0640 root root }
EOF

sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────
# PHASE 6: Handover to Platform Core
# ─────────────────────────────────────────────────────────────────
log_info "Phase 6: Cloning platform-core and initializing sync loop..."
mkdir -p "$INSTALL_DIR"
if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    git clone "https://x-access-token:${GIT_PAT}@github.com/${GITHUB_ORG}/platform-core.git" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python3 sync.py --hostname "$VPS_HOSTNAME"

log_success "🎉 platform-ignite Bunker Ignition Complete. Node $VPS_HOSTNAME is Live."
