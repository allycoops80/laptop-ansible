# laptop-ansible

Ansible playbook to provision a new laptop with standard developer tools.

Supports **Debian/Ubuntu** (apt) and **Fedora 44** (dnf). The OS family is
detected automatically at run time via the `ansible_os_family` fact — no
extra variable or flag is needed. Per-app installation logic lives under
`tasks/debian/*.yml` and `tasks/fedora/*.yml`, included conditionally from
`site.yml`; OS-independent tasks (git identity, Claude Code config, AWS
config, npm-based installs, repo cloning) stay directly in `site.yml`.

## What gets installed

| Tool | Debian/Ubuntu | Fedora |
|---|---|---|
| git | apt | dnf |
| GitHub CLI (`gh`) | cli.github.com apt repo | cli.github.com rpm repo |
| Python tools (pip, venv) | apt | dnf (venv ships with Fedora's `python3`) |
| Node.js + npm | apt | dnf |
| VS Code | Microsoft apt repo | Microsoft rpm repo |
| Slack | Packagecloud apt repo | Flathub (`com.slack.Slack`) — packagecloud rpm repo is stale |
| Claude Desktop | aaddrick unofficial Debian repo | **not installed** — no Fedora packaging exists from that source |
| Claude Code CLI | npm (`@anthropic-ai/claude-code`) | npm (`@anthropic-ai/claude-code`) |
| 1Password Desktop + CLI | 1Password apt repo | 1Password rpm repo |
| Zoom | zoom.us `.deb` download | zoom.us `.rpm` download |
| Brave Browser | Brave apt repo | Brave rpm repo |
| Obsidian | GitHub releases (`.deb` asset) | GitHub releases (official AppImage) |
| OpenTofu | packages.opentofu.org apt repo | Fedora's own repos (`opentofu` package) |
| OpenVPN 3 | packages.openvpn.net apt repo | **not installed** — `dsommers/openvpn3-linux` Copr repo has no fedora-44 build yet |
| AWS CLI v2 | awscli.amazonaws.com installer | awscli.amazonaws.com installer (same, arch-based) |
| AWS CDK | npm (`aws-cdk`) | npm (`aws-cdk`) |
| AWS Session Manager Plugin | AWS `.deb` download | AWS `.rpm` download |
| NFS client | `nfs-common` (apt) | `nfs-utils` (dnf) |
| AWS CLI config | files/aws_config (SSO profiles, no credentials) | files/aws_config (SSO profiles, no credentials) |

SSH agent is configured to use 1Password — see [SSH keys](#ssh-keys) below.

### Known gap: Claude Desktop on Fedora

Claude Desktop is installed via an unofficial Debian-only packaging project
(`aaddrick/claude-desktop-debian`). It has no RPM/Fedora equivalent, so the
`claude_desktop` tag is a no-op on Fedora hosts — it does not fail, it simply
installs nothing. Revisit if a trustworthy Fedora package becomes available.

### Known gap: OpenVPN 3 on Fedora

The `openvpn3` task is disabled (commented out) on Fedora because the
`dsommers/openvpn3-linux` Copr repo has no `fedora-44` build yet (confirmed:
`dnf copr enable` 404s on `.../fedora-44/`). Re-enable the include in
`site.yml` once Copr publishes a fedora-44 build.

## Bootstrap a new laptop

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/allycoops80/laptop-ansible/main/bootstrap.sh | bash
```

### Or step by step

```bash
sudo apt install git
git clone https://github.com/allycoops80/laptop-ansible.git ~/code/laptop-ansible
bash ~/code/laptop-ansible/bootstrap.sh
```

The script installs `git` and `ansible` via apt, clones this repo, then runs the playbook under `sudo`. You will be prompted once for your sudo password.

Repository cloning is skipped during bootstrap (SSH agent must be configured first). Run manually once 1Password is set up:

```bash
cd ~/code/laptop-ansible
sudo ansible-playbook -i inventory.ini site.yml -e "the_user=$USER" --tags repos
```

### Run a single component

```bash
cd ~/code/laptop-ansible
sudo ansible-playbook -i inventory.ini site.yml -e "the_user=$USER" --tags zoom
```

Available tags: `git`, `gh`, `python`, `nodejs`, `vscode`, `slack`, `claude_desktop`, `claude_code`, `claude_config`, `onepassword`, `zoom`, `brave`, `obsidian`, `tofu`, `openvpn3`, `awscli`, `awscdk`, `ssm_plugin`, `nfs`, `aws`, `repos`

Every tag works the same way on both Debian/Ubuntu and Fedora, except `claude_desktop`, which only does anything on Debian/Ubuntu (see [Known gap](#known-gap-claude-desktop-on-fedora) above).

## Why `sudo ansible-playbook` instead of `ansible-playbook -K`

This system's sudo/PAM configuration wraps Ansible's custom prompt in a format Ansible can't pattern-match, causing `-K` to time out. The workaround is to run the whole playbook as root (`sudo`) and use `become_method = su` for privilege operations — root can `su` to any user without a password via `pam_rootok.so`. The `the_user=$USER` variable must be passed explicitly because `sudo` resets `$USER` to `root` in the child process.

## First-time setup after provisioning

### Repositories

Most repos use SSH remotes, so Bitwarden SSH agent must be running and unlocked first. Run as a separate step once Bitwarden is set up:

```bash
sudo ansible-playbook -i inventory.ini site.yml -e "the_user=$USER" --tags repos
```

### AWS

Profiles are SSO-only — no static credentials are stored. Authenticate with:

```bash
aws sso login --profile production
```

### SSH keys

The playbook configures `~/.ssh/config` and `~/.bashrc` to use Bitwarden as the SSH agent (socket: `~/.bitwarden-ssh-agent.sock`).

To activate:

1. Open Bitwarden Desktop → Settings → SSH Agent → enable it
2. Import your SSH key via the Bitwarden CLI:

```bash
export BW_SESSION=$(bw unlock --raw)

python3 -c "
import json, subprocess
fp = subprocess.check_output(
    ['ssh-keygen', '-lf', '/home/$USER/.ssh/id_ed25519.pub']
).decode().split()[1]
item = {
    'type': 5,
    'name': 'Personal SSH Key',
    'sshKey': {
        'privateKey': open('/home/$USER/.ssh/id_ed25519').read(),
        'publicKey':  open('/home/$USER/.ssh/id_ed25519.pub').read().strip(),
        'keyFingerprint': fp
    }
}
print(json.dumps(item))
" | bw encode | bw create item --session "\$BW_SESSION"
```

Bitwarden will serve the key via the agent socket whenever the desktop app is running and unlocked.

## Maintaining this repo

To push changes from an existing machine (SSH available):

```bash
cd ~/code/laptop-ansible
git remote set-url origin git@github.com:allycoops80/laptop-ansible.git
git add -p
git commit -m "your message"
git push
```
