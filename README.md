# laptop-ansible

Ansible playbook to provision a new laptop with standard developer tools.

## What gets installed

| Tool | Method |
|---|---|
| git | apt (Ubuntu) |
| Node.js + npm | apt (Ubuntu) |
| VS Code | Microsoft apt repo |
| Slack | Packagecloud apt repo |
| Claude Desktop | aaddrick unofficial Debian repo |
| Claude Code CLI | npm (`@anthropic-ai/claude-code`) |
| Bitwarden Desktop | bitwarden.com download |
| Bitwarden CLI (`bw`) | npm (`@bitwarden/cli`) |
| Zoom | zoom.us download |
| Thorium Browser | GitHub releases (Alex313031/Thorium) |
| Obsidian | GitHub releases (obsidianmd/obsidian-releases) |
| AWS CLI config | files/aws_config (SSO profiles, no credentials) |

SSH agent is configured to use Bitwarden — see [SSH keys](#ssh-keys) below.

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

The script installs `git` and `ansible` via apt, clones this repo, then runs the playbook. You will be prompted once for your sudo password.

### Run a single component

```bash
cd ~/code/laptop-ansible
ansible-playbook -i inventory.ini site.yml -K --tags zoom
```

Available tags: `git`, `nodejs`, `vscode`, `slack`, `claude_desktop`, `claude_code`, `bitwarden`, `zoom`, `thorium`, `obsidian`, `aws`

## First-time setup after provisioning

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

Update `REPO_URL` in `bootstrap.sh` if the repo is ever moved.

To push changes from an existing machine (SSH available):

```bash
cd ~/code/laptop-ansible
git remote set-url origin git@github.com:allycoops80/laptop-ansible.git
git add -p
git commit -m "your message"
git push
```
