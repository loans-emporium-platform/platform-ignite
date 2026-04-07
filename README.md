# 🚀 platform-ignite (The Launcher)

## 🏛️ Functional Role: L0 (Sovereign Ignition)
This is the **Lean Public Launcher** for the V15 Sovereign Platform. Following the **Absolute Zenith (V15.55)** best practice, this script performs the **Ephemeral Identity-First Handshake**. 

All confidential OS hardening, software pinning, and business logic are safely stored in your private `platform-core` repository.

## 🔐 Key Features (Stage 1)
- **Burn-After-Reading (V15.48)**: The BWS access token is used only once during ignition and then purged forever from memory. No persistent vault credentials remain on disk.
- **Identity-First**: Prompts for a `VPS_HOSTNAME` before any configuration begins.
- **Minimal Footprint**: Installs only the bare essentials (`bws`, `git`, `jq`) required to pull the core engine.
- **Secure Handover**: Clones the private `platform-core` using a Just-in-Time `GIT_PAT` from your vault.

## ⚡ Quick Start
Execute the following command on a fresh Linux VPS using your temporary BWS token:

```bash
# One-liner to ignite your Sovereign VPS (V15.55)
curl -sSL https://raw.githubusercontent.com/Loans-Emporium/platform-ignite/master/bootstrap.sh | bash -s -- "YOUR_BWS_ACCESS_TOKEN"
```

### 📋 What you will need:
1.  **VPS_HOSTNAME**: A unique name for your server (e.g., `prod-vps-01`).
2.  **BWS_ACCESS_TOKEN**: Your temporary Bitwarden Secrets Manager access token.

## 🔄 Orchestration Lifecycle
1.  **Stage 1 (Ignite)**: `platform-ignite` establishes the ephemeral secret bridge.
2.  **Stage 2 (Refine)**: `platform-core` performs UFW hardening, Docker setup, and SSH lockdown.
3.  **Stage 3 (Operate)**: `platform-commander` manages the node via **High-Resolution Telemetry Heartbeats.**

---
> [!IMPORTANT]
> **Privacy First**: This repository contains no confidential configuration. All "how-to" logic for your infrastructure is gated behind your private GitHub authentication.
