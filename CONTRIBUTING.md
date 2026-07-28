<!-- mtoc-start -->

* [CONTRIBUTING](#contributing)
  * [Common Issues: Nix Binaries and Systemd](#common-issues-nix-binaries-and-systemd)
    * [Error Description](#error-description)
    * [Error Examples](#error-examples)
    * [Error Explanation](#error-explanation)
    * [Solutions](#solutions)
      * [1. Use Absolute Paths in Templates](#1-use-absolute-paths-in-templates)
      * [2. Create a Wrapper Script via Ansible](#2-create-a-wrapper-script-via-ansible)
      * [3. Create Symlinks](#3-create-symlinks)
      * [4. Set PATH in Service Unit Template](#4-set-path-in-service-unit-template)
    * [Recommended Ansible Implementation for SSHFS Mount Units](#recommended-ansible-implementation-for-sshfs-mount-units)
    * [Verifying the Solution via Ansible](#verifying-the-solution-via-ansible)

<!-- mtoc-end -->

# CONTRIBUTING

## Common Issues: Nix Binaries and Systemd

### Error Description

When using Ansible to create systemd service or mount units that invoke
binaries installed via Nix (NixOS, home-manager, or nix-profile), the units
fail with exit code 127 or cannot find the required executables. This occurs
because systemd units run with a minimal, sanitized PATH that doesn't include
Nix-specific binary locations.

### Error Examples

**Mount unit failure (exit code 127):**

```bash
× zsalt-shared.mount - /zsalt/shared
     Loaded: loaded (/home/user/.config/systemd/user/zsalt-shared.mount; enabled)
     Active: failed (Result: exit-code) since Tue 2026-07-28 17:08:38 MSK; 2min 54s ago
      Where: /zsalt/shared
       What: user@remote:/path/to/data
   Mem peak: 3.8M
        CPU: 6ms

Jul 28 17:08:38 hostname systemd[4261]: Mounting /zsalt/shared...
Jul 28 17:08:38 hostname systemd[4261]: zsalt-shared.mount: Mount process exited, code=exited, status=127/n/a
Jul 28 17:08:38 hostname systemd[4261]: zsalt-shared.mount: Failed with result 'exit-code'.
Jul 28 17:08:38 hostname systemd[4261]: Failed to mount /zsalt/shared.
```

**SSH connection failure when SSH binary is from Nix:**

```bash
× home-remote-share.mount - /home/user/remote/share
     Loaded: loaded (/home/user/.config/systemd/user/home-remote-share.mount; enabled)
     Active: failed (Result: exit-code) since Tue 2026-07-28 18:00:00 MSK; 1s ago
      Where: /home/user/remote/share
       What: user@remote:/path

Jul 28 18:00:00 hostname mount[12345]: ssh: command not found
```

### Error Explanation

Systemd units run with a restricted environment where `PATH` is set to
a minimal default (typically
`/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`). Nix stores its
binaries in non-standard locations:

* **User profiles:** `~/.nix-profile/bin/`
* **System profiles:** `/nix/var/nix/profiles/default/bin/`
* **NixOS system:** `/run/current-system/sw/bin/`
* **Individual packages:** `/nix/store/<hash>-<package>/bin/`

These paths are added to your shell's PATH by sourcing Nix profile scripts in
shell configuration files, but systemd doesn't source these files. Therefore,
any systemd unit that invokes Nix-installed binaries will fail unless the full
path is explicitly provided or the binary is made available in a standard PATH
location.

### Solutions

All solutions below should be implemented as Ansible tasks within your role to
avoid manual intervention.

#### 1. Use Absolute Paths in Templates

Detect the binary path with `which` and use it in your systemd unit template.

**Ansible tasks:**

```yaml
- name: Find SSHFS binary path
  ansible.builtin.command:
    cmd: "which sshfs"
  register: sshfs_path_check
  changed_when: false
  failed_when: false

- name: Set SSHFS binary path fact
  ansible.builtin.set_fact:
    sshfs_binary_path: "{{ sshfs_path_check.stdout }}"
  when: sshfs_path_check.rc == 0
```

**Template usage (for SSH mount options):**

```ini
[Mount]
What={{ sshfs_remote_user }}@{{ sshfs_remote_host }}:{{ sshfs_remote_path }}
Where={{ sshfs_local_path }}
Type=fuse.sshfs
Options={% for option in sshfs_options %}{{ option }}{% if not loop.last %},{% endif %}{% endfor %},ssh_command={{ sshfs_binary_path | default('/usr/bin/ssh') }}
```

**Pros:** Direct, no additional files created  **Cons:** Requires knowing which
options accept binary paths (e.g., `ssh_command` for SSHFS)

#### 2. Create a Wrapper Script via Ansible

Create a wrapper script in `~/.local/bin/` that sets up the Nix PATH before
executing the binary.

**Ansible tasks:**

```yaml
- name: Ensure local bin directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.local/bin"
    state: directory
    mode: '0755'

- name: Create SSHFS wrapper script with Nix PATH
  ansible.builtin.copy:
    content: |
      #!/bin/bash
      export PATH="{{ ansible_env.HOME }}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"
      exec sshfs "$@"
    dest: "{{ ansible_env.HOME }}/.local/bin/sshfs-wrapper"
    mode: '0755'
```

**Template usage (for service units with ExecStart):**

```ini
[Service]
ExecStart={{ ansible_env.HOME }}/.local/bin/sshfs-wrapper -o options source mountpoint
```

**Note:** For mount units, you may need to use `mount.fuse.sshfs` wrapper
instead, as mount units don't invoke binaries directly. Mount units look for
`mount.<type>` helper in PATH:

```yaml
- name: Create mount.sshfs wrapper for Nix
  ansible.builtin.copy:
    content: |
      #!/bin/bash
      export PATH="{{ ansible_env.HOME }}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"
      exec mount.fuse.sshfs "$@"
    dest: "{{ ansible_env.HOME }}/.local/bin/mount.fuse.sshfs"
    mode: '0755'
```

**Pros:** Flexible, can set environment variables for any binary  
**Cons:** Creates additional files to maintain

#### 3. Create Symlinks

Create symlinks from a standard PATH location to the Nix-installed binary.

**Ansible tasks (user-local, no sudo):**

```yaml
- name: Find SSHFS binary path
  ansible.builtin.command:
    cmd: "which sshfs"
  register: sshfs_path_check
  changed_when: false
  failed_when: false

- name: Ensure local bin directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.local/bin"
    state: directory
    mode: '0755'

- name: Create symlink for SSHFS in local bin
  ansible.builtin.file:
    src: "{{ sshfs_path_check.stdout }}"
    dest: "{{ ansible_env.HOME }}/.local/bin/sshfs"
    state: link
  when: sshfs_path_check.rc == 0

- name: Create symlink for SSH in local bin
  ansible.builtin.file:
    src: "{{ sshfs_path_check.stdout | dirname }}/ssh"
    dest: "{{ ansible_env.HOME }}/.local/bin/ssh"
    state: link
  when: sshfs_path_check.rc == 0
```

**Ansible tasks (system-wide, requires sudo):**

```yaml
- name: Create system-wide symlinks for Nix binaries
  ansible.builtin.file:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    state: link
  loop:
    - src: "{{ sshfs_path_check.stdout }}"
      dest: "/usr/local/bin/sshfs"
    - src: "{{ sshfs_path_check.stdout | dirname }}/ssh"
      dest: "/usr/local/bin/ssh"
  become: true
  when: sshfs_path_check.rc == 0 and 'nix' in sshfs_path_check.stdout
```

**Pros:** Transparent, no template changes needed, works for mount units  
**Cons:** Symlinks can break on Nix garbage collection (use `-sf` to force refresh)

#### 4. Set PATH in Service Unit Template

For service units, extend the PATH using the `Environment` directive in the template.

**Template example:**

```ini
[Service]
Environment="PATH={{ ansible_env.HOME }}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:{{ ansible_env.PATH }}"
ExecStart=sshfs -o options source mountpoint
```

**Pros:** Clean, single configuration point  
**Cons:** Only works for service units, not mount units

### Recommended Ansible Implementation for SSHFS Mount Units

For SSHFS mount units specifically (which have the most constraints), the
recommended approach combines symlinks and absolute paths:

```yaml
- name: Check if Nix environment is present
  ansible.builtin.stat:
    path: "{{ ansible_env.HOME }}/.nix-profile/bin/sshfs"
  register: nix_sshfs

- name: Ensure local bin directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.local/bin"
    state: directory
    mode: '0755'

- name: Create symlink for SSHFS from Nix profile
  ansible.builtin.file:
    src: "{{ ansible_env.HOME }}/.nix-profile/bin/sshfs"
    dest: "{{ ansible_env.HOME }}/.local/bin/sshfs"
    state: link
    force: true
  when: nix_sshfs.stat.exists

- name: Create symlink for SSH from Nix profile
  ansible.builtin.file:
    src: "{{ ansible_env.HOME }}/.nix-profile/bin/ssh"
    dest: "{{ ansible_env.HOME }}/.local/bin/ssh"
    state: link
    force: true
  when: nix_sshfs.stat.exists

- name: Add ~/.local/bin to user's systemd PATH
  ansible.builtin.lineinfile:
    path: "{{ ansible_env.XDG_CONFIG_HOME | default(ansible_env.HOME + '/.config') }}/environment.d/99-local-bin.conf"
    line: 'PATH={{ ansible_env.HOME }}/.local/bin:${PATH}'
    create: true
    mode: '0644'
```

Then in your mount unit template, specify the SSH command explicitly:

```ini
[Mount]
Options={% for option in sshfs_options %}{{ option }}{% if not loop.last %},{% endif %}{% endfor %},ssh_command={{ ansible_env.HOME }}/.local/bin/ssh
```

### Verifying the Solution via Ansible

Add verification tasks to your role:

```yaml
- name: Verify systemd can locate binaries
  ansible.builtin.command:
    cmd: "systemd-run --user --pty which sshfs"
  register: systemd_path_test
  changed_when: false
  failed_when: false

- name: Warn if binaries not in systemd PATH
  ansible.builtin.debug:
    msg: >
      WARNING: SSHFS binary not found in systemd PATH.
      Check symlinks in ~/.local/bin/ and environment.d configuration.
  when: systemd_path_test.rc != 0
```
