#!/usr/bin/env bash
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/allycoops80/laptop-ansible.git"
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
info "Running playbook..."
cd "$REPO_DIR"
# Capture the real username before sudo resets $USER to root.
# become_method=su lets root su to any user without a password (pam_rootok.so),
# bypassing the sudo prompt-matching issues on this system.
# repos is excluded — SSH agent must be set up first. Run manually after Bitwarden:
#   sudo ansible-playbook -i inventory.ini site.yml -e "the_user=$USER" --tags repos
sudo ansible-playbook -i inventory.ini site.yml \
    -e "the_user=$USER" \
    --skip-tags repos
