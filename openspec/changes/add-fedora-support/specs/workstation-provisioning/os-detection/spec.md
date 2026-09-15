## Purpose

Ensures the playbook identifies which OS family a target host belongs to (Debian/Ubuntu vs Fedora) and dispatches each package-manager-dependent installation to the correct task set for that family, without requiring the operator to specify the OS manually.

## ADDED Requirements

### Requirement: Runtime OS family detection
The playbook SHALL determine the target host's OS family automatically at run time using Ansible facts, without requiring an extra variable or command-line flag from the operator.

#### Scenario: Running on an Ubuntu/Debian host
- **WHEN** the playbook runs against a host where the OS family fact identifies Debian or Ubuntu
- **THEN** the Debian/Ubuntu (apt-based) task set is used for every package-manager-dependent installation step

#### Scenario: Running on a Fedora host
- **WHEN** the playbook runs against a host where the OS family fact identifies Fedora
- **THEN** the Fedora (dnf-based) task set is used for every package-manager-dependent installation step

#### Scenario: Running on an unsupported OS family
- **WHEN** the playbook runs against a host whose OS family is neither Debian/Ubuntu nor Fedora
- **THEN** the playbook SHALL fail fast with a clear error identifying the unsupported OS family, rather than silently attempting Debian- or Fedora-specific tasks

### Requirement: Tag-based selective execution preserved across OS families
Existing per-app tags (e.g. `git`, `gh`, `vscode`, `slack`, `brave`, `onepassword`, `tofu`, `awscli`, `openvpn3`, `nfs`, `repos`, etc.) SHALL continue to select the same logical set of work on both OS families, so that `--tags <tag>` behaves consistently regardless of which OS the play targets.

#### Scenario: Running with a tag on Fedora
- **WHEN** the operator runs the playbook against a Fedora host with `--tags vscode`
- **THEN** only the Fedora-specific VS Code installation tasks execute

#### Scenario: Running with a tag on Ubuntu/Debian
- **WHEN** the operator runs the playbook against an Ubuntu/Debian host with `--tags vscode`
- **THEN** only the Debian/Ubuntu-specific VS Code installation tasks execute, matching current behavior

### Requirement: OS-independent tasks run unconditionally
Tasks that do not depend on a package manager (git identity configuration, Claude Code config file copies, AWS config file copy, npm-based global tool installs, repository cloning) SHALL execute the same way regardless of detected OS family.

#### Scenario: Git identity configuration on either OS family
- **WHEN** the playbook runs against either a Debian/Ubuntu or a Fedora host
- **THEN** the git global `user.name` and `user.email` configuration steps run identically, with no OS-specific branching
