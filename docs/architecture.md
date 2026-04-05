# 🏛️ platform-ignite Architecture (L0 Foundation)

This document defines the **Sovereign Foundation Layer (L0)**. Its architectural role is to provide a "Zero-Trust" bootstrap environment for fresh VPS nodes.

## 1. The Provisioning Lifecycle
The bootstrap process follows a strict "Reset-to-Zero" model to ensure that every node is identical and stateless.

```mermaid
flowchart TD
    Start((Fresh VPS)) --> Auth[Authenticate via BSM Machine Token]
    Auth --> Baseline[Apply OS Hardening and Lockdown]
    Baseline --> Tools[Install Base Tooling: Docker, Tailscale, BWS, YQ]
    Tools --> Trust[Inject Initial Neon Config URL via BWS]
    Trust --> Handover[Handover to platform-core (Sovereign Runtime)]
```

## 2. Bootsequence: First Step
1. **Machine Token Generation**: The `platform-registry (The Commander)` generates a specific BSM Machine Token for the node.
2. **Environment Injection**: The token is piped into the `bootstrap.sh` script during initial `curl | bash`.
3. **Registry Discovery**: The node uses the token to fetch its **`NEON_DB_URL`** and its specific `VPS_HOSTNAME` from the Bitwarden vault.

## 3. Toolchain & Version Pinning
To prevent configuration drift, all infrastructure tools are pinned to specific versions:
- **Docker**: v24.0.x
- **Tailscale**: v1.5x
- **BWS (Bitwarden CLI)**: v0.x
- **Caddy**: v2.7.x
