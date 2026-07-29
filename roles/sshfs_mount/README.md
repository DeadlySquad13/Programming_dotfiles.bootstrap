# SshFs Mount role

Mainly used as a part of filesystem role on specific hosts (such as @salt).

## Usage

```yaml
- name: Configure SSHFS mount for work connection
  ansible.builtin.include_role:
    name: sshfs_mount
  vars:
    sshfs_remote_user: "apakalo"
    sshfs_remote_host: "creamsoda"
    sshfs_remote_path: "/Users/apakalo/Projects"
    sshfs_local_path: "/z{{ ansible_facts['nodename'] }}/shared-/@creamsoda/Projects_remote"
```

## Authentication

The service unit injects `SSH_AUTH_SOCK` from Ansible's environment so the SSH agent
is available. To bypass the agent, pass extra options via `sshfs_extra_options`:

```yaml
  vars:
    sshfs_extra_options:
      - "IdentitiesOnly=yes"
      - "IdentityFile=/home/ds13/.ssh/Work__apakalo@creamsoda"
```

These are appended to the defaults in `sshfs_options`. The actual private key path is
`~/.ssh/Work__apakalo@creamsoda` (named with `@` in the filename).
See [`CONTRIBUTING.md`](CONTRIBUTING.md) for debugging steps.
