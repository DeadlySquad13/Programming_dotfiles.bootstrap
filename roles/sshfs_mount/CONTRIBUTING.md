# Contributing — SSHFS Mount role

## Debugging SSH authentication

When the mount service fails with "Permission denied", the SSH agent is not being
reached or the identity file is incorrect.

### 1. Test SSH through systemd (must pass the env!)

```bash
systemd-run --user -p "Environment=SSH_AUTH_SOCK=$SSH_AUTH_SOCK" --wait \
  ssh -T <remote_user>@<remote_host>
```

### 2. Bypass the agent

Add `IdentitiesOnly=yes` with the correct `IdentityFile` via `sshfs_extra_options`:

```yaml
- name: Configure SSHFS mount for work connection
  ansible.builtin.include_role:
    name: sshfs_mount
  vars:
    sshfs_remote_user: "<user>"
    sshfs_remote_host: "<host>"
    sshfs_remote_path: "<path>"
    sshfs_local_path: "<path>"
    sshfs_extra_options:
      - "IdentitiesOnly=yes"
      - "IdentityFile=/home/<user>/.ssh/<key>"
```

These are appended to the defaults. This prevents SSH from trying agent keys and only
uses the specified identity.

### 3. Verify the rendered service unit

```bash
systemctl --user show <unit_name> --property ExecStart
systemctl --user show <unit_name> --property Environment
```
