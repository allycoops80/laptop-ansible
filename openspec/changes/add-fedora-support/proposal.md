## Why

This repo currently provisions Ubuntu/Debian workstations only, via a single flat `site.yml` using `apt` tasks. We now need to provision Fedora 44 workstations with the same baseline toolset, without maintaining a separate playbook or duplicating unrelated logic (git config, repo cloning, dotfile management, etc.).

## What Changes

- Detect the target OS family at runtime (`ansible_os_family` / `ansible_distribution`) and branch each package-manager-dependent task between Debian/Ubuntu (`apt`) and Fedora (`dnf`).
- Restructure package/app installation logic out of the flat `site.yml` into per-OS-family task files (e.g. `tasks/debian/*.yml`, `tasks/fedora/*.yml`), included conditionally from `site.yml` based on detected OS family. Shared, OS-independent tasks (git identity, Claude Code config copy, AWS config copy, repo cloning) remain in `site.yml` unchanged.
- Add Fedora/RPM equivalents for each Debian-only app currently installed via apt repos or `.deb` packages: GitHub CLI, Python tooling, Node.js/npm, VS Code, Slack, Zoom, Brave Browser, Obsidian, 1Password (+ CLI), OpenTofu, AWS CLI v2, OpenVPN 3, AWS Session Manager Plugin, AWS CDK (via npm, OS-independent), Claude Code CLI (via npm, OS-independent).
- **Known gap**: Claude Desktop has no supported RPM/Fedora packaging from its current unofficial source (`aaddrick/claude-desktop-debian` is Debian-only). It will be **skipped on Fedora** for this change — not installed, not blocking the rest of the playbook. This can be revisited later if a trustworthy Fedora package appears.
- Preserve existing per-app `tags` so `--tags <tag>` selection continues to work the same way on both OS families.
- Update `bootstrap.sh` and `README.md` to reflect Fedora as a supported target and document the new task-file layout.

## Capabilities

### New Capabilities
- `workstation-provisioning/os-detection`: Runtime detection of the host OS family (Debian/Ubuntu vs Fedora) and dispatch to the correct per-OS task set.
- `workstation-provisioning/fedora-baseline`: Installing the Fedora 44 (dnf/rpm-based) equivalent of every package/app currently installed on Debian/Ubuntu, including the documented Claude Desktop exception.

### Modified Capabilities
(none — no existing specs predate this change)

## Impact

- **Affected files**: `site.yml` (restructured to include per-OS task files and add OS-detection logic), new `tasks/debian/*.yml` and `tasks/fedora/*.yml` files, `bootstrap.sh`, `README.md`.
- **Affected systems**: Laptop provisioning only; no production/AWS infrastructure impact.
- **Compatibility**: Existing Debian/Ubuntu behavior and tags must be preserved exactly (task content moves, not changes, for the Debian side).
- **Dependencies**: New Fedora/RPM upstream repos and GPG keys for GitHub CLI, VS Code, Slack, Brave, 1Password, OpenTofu, OpenVPN 3 (each has an official or well-established Fedora/RPM distribution channel).
