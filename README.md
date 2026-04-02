# ansible-hostname-aschii

Ansible role that sets up a dynamic login experience on Linux servers:

- ASCII hostname banner rendered by `figlet` shown at login (MOTD)
- Pre-authentication SSH banner with environment and warning text
- Works on Debian and RHEL family distributions

## Requirements

- Ansible >= 2.15
- Target: Debian 12 (Bookworm) or RHEL 8/9 / Rocky Linux 8/9
- `figlet` installed by the role via the system package manager

## Quick Start

```yaml
- hosts: servers
  become: true
  roles:
    - role: ansible-hostname-aschii
      vars:
        motd_env: "PRODUCTION"
        motd_warn: "Authorized access only"
        motd_note: "Web application server — handle with care"
```

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `banner` | `true` | Enable pre-auth SSH banner in `/etc/ssh/sshd_config` |
| `motd_env` | `PRODUCTION` | Environment label shown in MOTD and SSH banner |
| `motd_warn` | `AUTHORIZED ACCESS ONLY` | Warning line shown in MOTD and SSH banner |
| `motd_note` | `Unauthorized access is strictly prohibited...` | Note shown below the warning |

## What Gets Deployed

### Dynamic MOTD (`/usr/local/bin/dynmotd`)

Executed at login via `/etc/profile`. Displays:

- ASCII hostname rendered by `figlet`
- Environment, warning, and note lines centered to terminal width
- OS description, kernel version, and uptime

### SSH Pre-auth Banner (`/etc/ssh/banner`)

Static text file shown before password prompt. Controlled by `banner: true`.
Contains hostname, environment, warning, and note from the role variables.

## Testing

### Molecule (CI)

```bash
pip install molecule molecule-plugins[docker] ansible docker

molecule test
```

### Lima (local)

```bash
bash tests/test.sh
```

The script creates a Debian 12 Lima VM, installs dependencies, and runs
the playbook. Requires [Lima](https://lima-vm.io) (`brew install lima`).

To clean up after testing:

```bash
limactl stop hostname-ascii-test
limactl delete hostname-ascii-test
```

## License

Apache-2.0
