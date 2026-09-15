## Context

See proposal.md - Why. Today `site.yml` is one flat play targeting `hosts: local` with per-app tasks tagged individually, all using the `apt` module or direct `.deb` downloads. There are no roles and no `tasks/` directory. `bootstrap.sh` is the one-time entry point that installs Ansible itself before `site.yml` runs.

## Goals / Non-Goals

**Goals:**
- Same tag names (`git`, `gh`, `python`, `nodejs`, `vscode`, `slack`, `zoom`, `brave`, `obsidian`, `onepassword`, `tofu`, `awscli`, `openvpn3`, `ssm_plugin`, `nfs`, `repos`, `awscdk`, `claude_code`, `claude_config`, `aws`) work unchanged on both OS families.
- Debian/Ubuntu behavior is preserved byte-for-byte in effect (tasks moved, not altered), so existing hosts see no change.
- Fedora 44 hosts reach functional parity for every app except Claude Desktop (explicitly out of scope, see proposal).

**Non-Goals:**
- Not building a general N-distro abstraction (e.g. openSUSE, Arch) - only Debian/Ubuntu and Fedora.
- Not solving Claude Desktop on Fedora in this change - tracked as a known gap.
- Not converting the repo to use Ansible roles - the task-file split is a lighter-weight restructuring than a full role.

## Decisions

### 1. Split into per-OS-family `include_tasks` files rather than inlining `when: ansible_os_family == ...` on every task
Each app gets a `tasks/debian/<app>.yml` and a `tasks/fedora/<app>.yml` (e.g. `tasks/debian/vscode.yml`, `tasks/fedora/vscode.yml`). `site.yml` keeps its tags on `include_tasks` blocks, one pair per app, with `when: ansible_os_family == "Debian"` / `== "Fedora"` guarding which file is pulled in.

- **Why**: The user chose this over single-file conditional tasks. It keeps each OS's task list linearly readable (no interleaved apt/dnf blocks), makes future per-OS additions a one-file change, and keeps `site.yml` as a short table of contents.
- **Alternative considered**: Inline `when:` on every existing task, duplicated per package manager, in the same file. Rejected per user preference - would make `site.yml` roughly double in length and harder to scan.

### 2. OS family detection via `ansible_os_family`, gated with an explicit `assert`/`fail` for unsupported families
A `pre_tasks` block asserts `ansible_os_family in ['Debian', 'Fedora']` before any tagged work runs, failing with a clear message otherwise.

- **Why**: Matches the existing `the_user` guard pattern already in `site.yml` (`fail` in `pre_tasks`), and prevents a partially-applied run on an unsupported OS.
- **Alternative considered**: Let unmatched hosts simply skip every `when:` and silently do nothing. Rejected - a silent no-op on a typo'd or unsupported OS is worse than a clear failure.

### 3. OS-independent tasks stay directly in `site.yml`
Git identity config, Claude Code CLI/config, AWS config copy, AWS CDK (npm), and repo cloning are not moved into per-OS files - they already have no package-manager dependency.

- **Why**: Avoids needless churn; only genuinely OS-dependent logic moves.

### 4. Fedora package source mapping (one-to-one with existing Debian sources)

| App | Debian/Ubuntu source (existing) | Fedora source (new) |
|---|---|---|
| git | apt | dnf (Fedora repo) |
| gh | GitHub CLI apt repo | GitHub CLI's official yum/rpm repo |
| python | `python3-venv`, `python3-pip` (apt) | `python3-pip` (dnf); `venv` ships in Fedora's `python3` package already |
| nodejs | `nodejs`, `npm` (apt) | `nodejs`, `npm` (dnf) |
| vscode | Microsoft apt repo | Microsoft's official yum repo (`packages.microsoft.com/yumrepos/vscode`) |
| slack | packagecloud apt repo | Direct `.rpm` download from Slack (no stable Fedora repo published), same pattern as `zoom` |
| zoom | direct `.deb` download | direct `.rpm` download (`zoom_x86_64.rpm`) |
| brave | Brave apt repo | Brave's official rpm repo (`brave-browser-rpm-release.s3.brave.com`) |
| obsidian | latest GitHub release `.deb` asset | latest GitHub release `.rpm` asset (same `selectattr` pattern, filtered on `.rpm`) |
| onepassword | 1Password apt repo + debsig policy | 1Password's official rpm repo + GPG key (no debsig equivalent needed - rpm packages are GPG-signed directly) |
| tofu | OpenTofu apt/deb repo | OpenTofu's official rpm repo |
| awscli | official installer zip (arch-based, not distro-based) | same installer zip - unchanged, only `unzip` now comes from `dnf` |
| openvpn3 | OpenVPN 3 apt repo (noble) | OpenVPN's published Fedora rpm repo |
| ssm_plugin | direct `.deb` download | direct `.rpm` download (`session-manager-plugin.rpm`) |
| nfs | `nfs-common` (apt) | `nfs-utils` (dnf) |
| claude_desktop | unofficial apt repo (`aaddrick/claude-desktop-debian`) | **skipped** - no Fedora equivalent from that source (see proposal) |

### 5. `bootstrap.sh` gains an OS branch for installing Ansible itself
Fedora doesn't have `apt`; bootstrap needs a `dnf install ansible` (or equivalent) path before `site.yml` can run at all.

- **Why**: Without this, Fedora users have no way to get Ansible installed in the first place.

## Risks / Trade-offs

- **Vendor Fedora repos may lag or differ in reliability from their apt counterparts** (e.g. Slack has no official Fedora repo at all) → Mitigation: use direct `.rpm` download where no repo exists, same pattern already proven for Zoom/SSM plugin on Debian side.
- **OpenVPN3's Fedora rpm repo naming/versioning may not track Fedora 44 immediately** (same class of issue as the existing `noble` comment for Ubuntu 26.04) → Mitigation: document the assumption in a task comment, same convention already used in `site.yml`.
- **Duplicated task logic across debian/ and fedora/ files for the same app increases file count without behavior sharing** → Mitigation: accepted trade-off per user's explicit preference for per-OS task files over inline conditionals.
- **Claude Desktop gap reduces Fedora parity** → Mitigation: explicitly documented in README and proposal; revisit if a trustworthy Fedora package appears later.

## Migration Plan

Not applicable in the traditional sense (no running service to migrate) - this is additive to an idempotent provisioning playbook. Existing Debian/Ubuntu hosts are unaffected since re-running the restructured playbook against them takes the same `tasks/debian/*.yml` path with identical task content. No rollback beyond reverting the commit is needed.
