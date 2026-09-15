## Purpose

Defines the baseline set of tools and applications that must be installed and configured on a Fedora 44 workstation so it reaches functional parity with an Ubuntu/Debian workstation provisioned by this repo, including the one documented exception.

## ADDED Requirements

### Requirement: Fedora package manager prerequisites
On a Fedora host, the playbook SHALL install the `dnf`-based equivalents of the apt prerequisites (curl, wget, gpg, ca-certificates, and any `dnf-plugins-core`/`config-manager` capability needed to add third-party repos) before any app-specific installation task runs.

#### Scenario: Prerequisites installed before app installs
- **WHEN** the playbook runs against a Fedora host
- **THEN** curl, wget, gpg, and ca-certificates are present, and repo-management tooling is available, before any tagged app-installation task attempts to add a repository or install a package

### Requirement: Core developer tooling on Fedora
The playbook SHALL install git, GitHub CLI (`gh`), Python tooling (pip and venv support), and Node.js with npm on Fedora using `dnf` and the same tags (`git`, `gh`, `python`, `nodejs`) used on Debian/Ubuntu.

#### Scenario: GitHub CLI installed on Fedora
- **WHEN** the playbook runs the `gh` tag against a Fedora host
- **THEN** the GitHub CLI's official Fedora/RPM repository is registered and the `gh` package is installed via `dnf`

### Requirement: GUI and desktop applications on Fedora
The playbook SHALL install VS Code, Slack, Zoom, Brave Browser, and Obsidian on Fedora using their official or well-established RPM distribution channels (official `dnf` repo where one exists, or direct `.rpm` download where the vendor does not provide a Fedora repo), under the same tags used on Debian/Ubuntu (`vscode`, `slack`, `zoom`, `brave`, `obsidian`).

#### Scenario: VS Code installed on Fedora
- **WHEN** the playbook runs the `vscode` tag against a Fedora host
- **THEN** Microsoft's official Fedora/RPM repository is registered and the `code` package is installed via `dnf`

#### Scenario: Obsidian installed on Fedora
- **WHEN** the playbook runs the `obsidian` tag against a Fedora host
- **THEN** the latest Obsidian GitHub release's `.rpm` asset is downloaded and installed, mirroring how the `.deb` asset is resolved and installed on Debian/Ubuntu

### Requirement: 1Password on Fedora
The playbook SHALL install the 1Password desktop app and CLI on Fedora using 1Password's official RPM repository and signing key, and SHALL configure the 1Password SSH agent socket the same way as on Debian/Ubuntu, under the `onepassword` tag.

#### Scenario: 1Password SSH agent configured on Fedora
- **WHEN** the playbook runs the `onepassword` tag against a Fedora host
- **THEN** the user's SSH config is updated to use the 1Password SSH agent socket, identically to the Debian/Ubuntu behavior

### Requirement: Infrastructure and cloud CLI tooling on Fedora
The playbook SHALL install OpenTofu, AWS CLI v2, OpenVPN 3, and the AWS Session Manager Plugin on Fedora using each vendor's official Fedora/RPM distribution channel, under the same tags used on Debian/Ubuntu (`tofu`, `awscli`, `openvpn3`, `ssm_plugin`).

#### Scenario: AWS CLI v2 installed on Fedora
- **WHEN** the playbook runs the `awscli` tag against a Fedora host
- **THEN** the same official AWS-provided installer script/zip flow used on Debian/Ubuntu is used on Fedora, since it is architecture-based rather than distro-package-based

### Requirement: NFS mount support on Fedora
The playbook SHALL install the Fedora NFS client package (`nfs-utils`) in place of the Debian `nfs-common` package, and configure the same Synology music share mount, under the `nfs` tag.

#### Scenario: NFS mount configured on Fedora
- **WHEN** the playbook runs the `nfs` tag against a Fedora host
- **THEN** `nfs-utils` is installed and the `/mnt/music` NFS mount is present in `fstab`, matching the Debian/Ubuntu mount configuration

### Requirement: Documented Claude Desktop gap on Fedora
The playbook SHALL NOT attempt to install Claude Desktop on Fedora hosts, because the currently-used unofficial packaging source only publishes Debian/Ubuntu `.deb` packages. This exclusion SHALL be explicit (an OS-conditional skip) rather than a silent failure, and SHALL be documented in the README.

#### Scenario: Claude Desktop tag run on Fedora
- **WHEN** the playbook runs the `claude_desktop` tag against a Fedora host
- **THEN** no Claude Desktop installation tasks execute, no task fails, and the play completes without attempting a Debian-only package source

#### Scenario: Claude Desktop tag run on Ubuntu/Debian
- **WHEN** the playbook runs the `claude_desktop` tag against a Debian/Ubuntu host
- **THEN** Claude Desktop installs exactly as it does today, unaffected by the Fedora exclusion
