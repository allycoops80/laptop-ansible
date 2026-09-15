## 1. Bootstrap and OS detection

- [x] 1.1 Add a Fedora branch to `bootstrap.sh` that installs Ansible via `dnf` (alongside the existing Debian/Ubuntu apt branch), detecting OS via `/etc/os-release`.
- [x] 1.2 Add a `pre_tasks` assertion in `site.yml` that fails fast with a clear message when `ansible_os_family` is not `Debian` or `Fedora`.
- [x] 1.3 Create `tasks/debian/` and `tasks/fedora/` directories.

## 2. Extract existing Debian/Ubuntu tasks unchanged

- [x] 2.1 Move each existing apt-based/`.deb`-based task block out of `site.yml` into its own `tasks/debian/<app>.yml` file (git, gh, python, nodejs, vscode, slack, claude_desktop, zoom, brave, obsidian, onepassword, tofu, awscli, openvpn3, ssm_plugin, nfs), preserving task names, module args, and tags exactly.
- [x] 2.2 Replace each moved block in `site.yml` with an `include_tasks: tasks/debian/<app>.yml` guarded by `when: ansible_os_family == "Debian"`, keeping the same tag(s) on the `include_tasks` block.
- [ ] 2.3 Run the playbook (or `--check`) against an existing Ubuntu/Debian host and confirm no task names, tags, or behavior changed. **Not run** — requires a real/VM Debian-family host; `ansible-playbook --syntax-check` passes (see Validation notes below), but no host was available in this session to execute against.

## 3. Fedora task files - core developer tooling

- [x] 3.1 `tasks/fedora/git.yml`: install `git` via `dnf`.
- [x] 3.2 `tasks/fedora/gh.yml`: register GitHub CLI's official rpm repo and install `gh` via `dnf`.
- [x] 3.3 `tasks/fedora/python.yml`: install `python3-pip` via `dnf` (venv ships with Fedora's `python3`).
- [x] 3.4 `tasks/fedora/nodejs.yml`: install `nodejs` and `npm` via `dnf`.
- [x] 3.5 Wire each of the above into `site.yml` as `include_tasks: tasks/fedora/<app>.yml`, guarded by `when: ansible_os_family == "Fedora"`, with the matching existing tag.

## 4. Fedora task files - desktop applications

- [x] 4.1 `tasks/fedora/vscode.yml`: register Microsoft's official Fedora/rpm repo and install `code` via `dnf`.
- [x] 4.2 `tasks/fedora/slack.yml`: install Slack via packagecloud's Enterprise Linux (rpm) repo channel (no stable Fedora repo exists; more maintainable than a hardcoded `.rpm` version URL).
- [x] 4.3 `tasks/fedora/zoom.yml`: download and install Zoom's `.rpm` directly, mirroring the existing Debian `.deb` download task.
- [x] 4.4 `tasks/fedora/brave.yml`: register Brave's official rpm repo and install `brave-browser` via `dnf`.
- [x] 4.5 `tasks/fedora/obsidian.yml`: resolve the latest Obsidian GitHub release's `.rpm` asset URL and install it, mirroring the existing `.deb` asset resolution logic.
- [x] 4.6 Wire each of the above into `site.yml` with the matching existing tag, guarded by `when: ansible_os_family == "Fedora"`.
- [x] 4.7 Add a Fedora-guarded no-op/skip note for `claude_desktop` (no `tasks/fedora/claude_desktop.yml` - the `claude_desktop` tag simply has no Fedora `include_tasks` block) and add a comment in `site.yml` referencing the documented gap.

## 5. Fedora task files - infrastructure and cloud tooling

- [x] 5.1 `tasks/fedora/onepassword.yml`: register 1Password's official rpm repo and GPG key, install `1password` and `1password-cli` via `dnf`; SSH agent socket config was already OS-independent and stayed in `site.yml` unchanged.
- [x] 5.2 `tasks/fedora/tofu.yml`: register OpenTofu's official rpm repo and install `tofu` via `dnf`.
- [x] 5.3 `tasks/fedora/awscli.yml`: reuse the existing arch-based AWS CLI v2 installer zip flow, with `unzip` installed via `dnf`.
- [x] 5.4 `tasks/fedora/openvpn3.yml`: enable the community `dsommers/openvpn3-linux` Copr repo and install `openvpn3` via `dnf` (no official OpenVPN-published Fedora repo exists; flagged in-file as an assumption to verify, same as the existing Ubuntu "noble" caveat).
- [x] 5.5 `tasks/fedora/ssm_plugin.yml`: download and install the AWS Session Manager Plugin's `.rpm` directly.
- [x] 5.6 `tasks/fedora/nfs.yml`: install `nfs-utils` via `dnf` and configure the same `/mnt/music` NFS mount.
- [x] 5.7 Wire each of the above into `site.yml` with the matching existing tag, guarded by `when: ansible_os_family == "Fedora"`.

## 6. Documentation

- [x] 6.1 Update `README.md` to list Fedora 44 as a supported target, describe the `tasks/debian/` and `tasks/fedora/` layout, and document the Claude Desktop Fedora gap. Also corrected a pre-existing stale tags list and one stale Bitwarden reference encountered in the same section (site.yml has used 1Password for several commits).
- [x] 6.2 Update the `site.yml` header comment (bootstrap/run instructions) to mention the Fedora bootstrap path.

## 7. Validation

- [ ] 7.1 Run the full playbook against a Fedora 44 VM/container and confirm every tag except `claude_desktop` completes successfully. **Not run** — no Fedora VM/container was available in this session.
- [ ] 7.2 Spot-check `--tags <app>` selective runs on Fedora for at least: `gh`, `vscode`, `onepassword`, `nfs`. **Not run** — same reason as 7.1.
- [ ] 7.3 Re-run the full playbook against an existing Ubuntu/Debian host and confirm behavior is unchanged (idempotent, same tags, no new failures). **Not run** — would require executing privileged installs against a real machine; only static validation was performed (see below).

### Validation performed this session (static, no live hosts)

- `python3 -c "import yaml; yaml.safe_load(...)"` over every new/changed `.yml` file: all parse cleanly.
- `ansible-playbook -i inventory.ini site.yml --syntax-check` (with `community.general` collection installed in a throwaway venv): passes with no errors.
- Manual review confirming every Debian task file's content is byte-for-byte identical to what previously lived inline in `site.yml` (module names, args, tags), other than removing the now-redundant per-task `tags:` line (tags on the `include_tasks` block propagate to all included tasks).
