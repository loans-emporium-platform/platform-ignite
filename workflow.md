# Platform-Ignite Workflows

This document outlines the workflows implemented in the platform-ignite repository, which serves as the L0 Ignition Phase for the Sovereign Zenith platform. It provides a minimal, secure bootstrap for provisioning VPS nodes.

## Overview of Key Components
- **bootstrap.sh**: The core script for node ignition.
- **README.md**: User documentation.
- **docs/architecture.md**: Technical details.

## 1. Bootstrap Ignition Workflow
**Purpose**: Establish secure identity-link for a bare VPS and prepare for runtime deployment.

**Steps**:
1. **Tool Installation**: Install curl, jq, unzip, git (if not present).
2. **BWS Setup**: Download Bitwarden SDK (bws v1.0.0) from GitHub releases.
3. **Authentication**: Accept BWS access token as argument or prompt interactively.
4. **Secret Retrieval**: Use bws to fetch DATABASE_URL, MASTER_ENCRYPTION_KEY, and BOOTSTRAP_PAT from Bitwarden vault.
5. **Local Hardening**: Write secrets to `/opt/platform/config/.env` with chmod 600 (root-only).
6. **Repository Cloning**: Use GIT_PAT to clone platform-core repo from GitHub.
7. **Token Cleanup**: Unset BWS_ACCESS_TOKEN and BOOTSTRAP_PAT to purge from memory.
8. **Handoff**: Execute `./setup.sh` from cloned repo to continue with platform-brain setup.

**Code Location**: `bootstrap.sh`

**Triggers**: Manual execution: `curl -sSL https://raw.githubusercontent.com/.../bootstrap.sh | bash -s -- "BWS_TOKEN"`

**Security Features**:
- Burn-After-Reading: Tokens destroyed immediately after use.
- Ephemeral Secrets: Only .env remains on disk.
- Defensive Scripting: `set -euo pipefail` prevents silent failures.
- Minimal Attack Surface: Only essential tools installed.

## Integration with Other Repositories
- **platform-commander**: Provides vault secrets.
- **platform-core**: Receives handoff for full setup.
- **platform-blueprint**: Follows architecture guidelines.

## Notes
- No additional workflows; this is a single-purpose bootstrap tool.
- For production, add checksum validation for bws binary and audit logging.
- Version: V15.5 (aligned with Sovereign Zenith).