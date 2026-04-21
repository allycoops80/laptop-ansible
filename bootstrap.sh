#!/usr/bin/env bash
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/alancooper/laptop-ansible.git"   # update before first use
REPO_DIR="$HOME/code/laptop-ansible"

# ── Helpers ────────────────────────────────────────────────────────────────
info()  { echo "==> $*"; }
abort() { echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && abort "Run as your normal user, not root (the playbook uses sudo internally)."

# ── Prerequisites ──────────────────────────────────────────────────────────
info "Installing git and ansible..."
sudo apt-get update -qq
sudo apt-get install -y git ansible

# ── Repo ───────────────────────────────────────────────────────────────────
if [[ -d "$REPO_DIR/.git" ]]; then
    info "Repo already present — pulling latest..."
    git -C "$REPO_DIR" pull
else
    info "Cloning $REPO_URL..."
    mkdir -p "$HOME/code"
    git clone "$REPO_URL" "$REPO_DIR"
fi

# ── Playbook ───────────────────────────────────────────────────────────────
info "Running playbook (you will be prompted for your sudo password)..."
cd "$REPO_DIR"
ansible-playbook -i inventory.ini site.yml -K
