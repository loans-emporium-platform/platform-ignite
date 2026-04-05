# 🚀 platform-ignite (The Launcher)

## 🚀 Functional Role: L0 (Foundation)
This is the **Public Launcher** for the V15 Sovereign Platform. Its only purpose is to perform the "Secret Zero" bootstrap of a fresh VPS node, preparing it for management by the **Platform Commander** (`platform-registry`).

## Features
- **OS Hardening**: UFW and SSH lockdown via Tailscale.
- **Base Toolchain**: Docker, BWS, Rclone, YQ, Git.
- **Trust Initialization**: Bitwarden Machine Token (BWS) injection.

## Quick Start
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Loans-Emporium/platform-ignite/main/bootstrap.sh)
```

## 📖 Documentation
- **[Detailed Architecture](docs/architecture.md)**: Deep dive into the L0 provisioning logic.
