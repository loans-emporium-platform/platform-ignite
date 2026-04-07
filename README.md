# 🚀 platform-ignite (The Launcher)

## 🏛️ Functional Role: L0 (Sovereign Ignition)
This is the **Lean Public Launcher** for the V15 Sovereign Platform. Following the "Two-Stage" best practice, this script performs only the **Identity-First Handshake**. 

All confidential OS hardening, software pinning, and business logic are safely stored in your private `platform-core` repository.

## 🔐 Key Features (Stage 1)
- **Zero-Trust Bridge**: Establishes a secure connection via **Bitwarden BWS** at runtime.
- **Identity-First**: Prompts for a `VPS_HOSTNAME` before any configuration begins.
- **Minimal Footprint**: Installs only the bare essentials (`bws`, `git`, `jq`) required to pull the core engine.
- **Secure Handover**: Clones the private `platform-core` using a Just-in-Time `GIT_PAT` from your vault.

## ⚡ Quick Start
Execute the following command on a fresh Linux VPS:

```bash
# One-liner to ignite your Sovereign VPS
bash <(curl -fsSL https://raw.githubusercontent.com/Loans-Emporium/platform-ignite/main/bootstrap.sh)
```

### 📋 What you will need:
1.  **VPS_HOSTNAME**: A unique name for your server (e.g., `prod-db-01`).
2.  **BWS_ACCESS_TOKEN**: Your Bitwarden Secrets Manager access token.

## 🔄 Orchestration Lifecycle
1.  **Stage 1 (Ignite)**: `platform-ignite` establishes the secret bridge.
2.  **Stage 2 (Refine)**: `platform-core` performs UFW hardening, Docker setup, and SSH lockdown.
3.  **Stage 3 (Operate)**: `platform-registry` (Commander) manages the node via hourly cron pulls.

---
> [!IMPORTANT]
> **Privacy First**: This repository contains no confidential configuration. All "how-to" logic for your infrastructure is gated behind your private GitHub authentication.
