# platform-ignite

## Purpose

**platform-ignite** is the **L0 Sovereign Ignition Layer** — a minimal public Bash bootstrap tool that runs once on a fresh Linux VPS. It establishes a zero-trust secure handshake, fetches secrets from Bitwarden, and hands off to `platform-core` for Stage 2 configuration.

This is intentionally lean and public: no confidential infrastructure logic lives here. All private runtime logic is in the private `platform-core` repo.

**Codename:** Ghost Ignition  
**Stage:** 1 of 3 in the provisioning lifecycle

---

## Folder Structure

```
platform-ignite/
├── bootstrap.sh          # The only executable — the entire ignition logic
├── README.md             # User-facing documentation and quick start
├── workflow.md           # Internal workflow and integration documentation
├── docs/
│   └── architecture.md   # Technical architecture of the L0 foundation layer
└── .gitignore
```

No `package.json`. No `requirements.txt`. This is a pure Bash project.

---

## What bootstrap.sh Does (8 Steps)

1. Install essential tools via `apt-get`: `curl`, `jq`, `unzip`, `git`
2. Download and install the **Bitwarden BWS CLI** (`bws` v1.0.0)
3. Accept `BWS_ACCESS_TOKEN` — from env var or interactive prompt (one-time use)
4. Capture `VPS_HOSTNAME` before any irreversible changes (Identity-First pattern)
5. Fetch three critical seeds from Bitwarden vault:
   - `DATABASE_URL`
   - `MASTER_ENCRYPTION_KEY`
   - `BOOTSTRAP_PAT` (GitHub Personal Access Token for cloning)
6. Write secrets to `/opt/platform/config/.env` with `chmod 600`
7. Clone `platform-core` from GitHub using the authenticated PAT
8. Execute `platform-core/setup.sh` (Stage 2 handoff)
9. **Burn-after-reading** — unset and purge all ephemeral tokens from memory

---

## How to Run

**Production (one-liner):**
```bash
curl -sSL https://raw.githubusercontent.com/loans-emporium-platform/platform-ignite/master/bootstrap.sh \
  | bash -s -- "YOUR_BWS_ACCESS_TOKEN"
```

**With environment variables:**
```bash
export BWS_ACCESS_TOKEN="your_token"
export VPS_HOSTNAME="prod-vps-01"
./bootstrap.sh
```

**Interactive (prompts for inputs):**
```bash
./bootstrap.sh
# Prompts for: BWS Access Token and VPS Hostname
```

---

## Security Model

- **Burn-after-reading**: All ephemeral tokens are unset from shell memory immediately after use.
- **Identity-first**: Hostname is captured before any irreversible changes.
- **Minimal footprint**: Only installs the bare minimum needed to hand off.
- **No secrets stored**: Nothing confidential lives in this repo.
- **One-time token**: BWS_ACCESS_TOKEN is single-use and discarded.

---

## Integration with Other Repos

| Repo | Relationship |
|---|---|
| `platform-core` | Cloned by this script; `setup.sh` is the Stage 2 handoff target |
| `platform-commander` | Provides Machine Token generation and post-bootstrap node management |
| `platform-blueprint` | Defines architecture guidelines this script follows |

---

## Provisioning Lifecycle Position

```
[platform-ignite]  →  [platform-core/setup.sh]  →  [platform-core/sync.py (cron)]
     Stage 1                  Stage 2                        Stage 3
  Identity + Secrets       OS Hardening               Autonomous Reconciliation
```

---

## Key Files

| File | Purpose |
|---|---|
| `bootstrap.sh` | Core 79-line executable — the entire ignition logic |
| `README.md` | Quick start, requirements, and lifecycle overview |
| `workflow.md` | Detailed 8-step bootstrap process and integration notes |
| `docs/architecture.md` | Boot sequence, toolchain version pinning, provisioning flowchart |
