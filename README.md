# My dotfiles

Configure Unix workstation using Ansible.

## Get started
Use `./bin/dot-bootstrap` (should be executable) to install required packages for
ansible. Once installed press cancel ('3') because you're most likely will need
some extra variables set in the vault.

To configure variables for current host (most importantly password) go to `group_vars`
and create a new host with variables. Passwords here are only referencing encrypted vault.
To edit vault you have to find a master password inn keepass and populate `.vault_pass.py` in the root of the repo.
See `.vault_pass.py.example` for example. You will most likely need to make `.vault_pass.py` executable.

After that you will be ready to edit vault:
```sh
ansible-vault edit --vault-password-file .vault_pass.py ./group_vars/<host_name>/vault
```

After that you're ready to go!

## Common pitfalls
### Hosts
Note that when you're running playbook, it will try to deploy it to all the hosts in `hosts.ini` file.
Limit it to the only hosts you need.

### Ansible.cfg in world writable directory
When running from shared directory in multisystem setup (Windows + WSL included) you will get errors and `ansible.cfg`
will be ignored (and hosts too). To fix it, the easiest way is to pass it directly as a variable when running scipt:
```sh
ANSIBLE_CONFIG=ansible.cfg ./bin/dot-bootstrap
```

### Languages

Languages are managed with [asdf](https://asdf-vm.com/#/).

- Ruby
- Golang
- Nodejs
- Python
- Elixir
- Terraform

### System

- fzf
- git
- tmux
- vim
- zsh

### Services

- redis

### Packages

- snap
- apt

## Bootstrap

Firt setup installation run the dot-bootstrap command.

```
$ ./bin/dot-bootstrap
```

After that you can run any scripts defined in the `$DOTFILES_PATH/bin`

```
$ dot-bootstrap
```

## Structure
When the program is used in combination with another role, create a new task in
the same folder nearby and import it. For example, `terminal-icons` is installed
alongside `powershell`. If it is used with multiple roles, then use tags:
`oh_my_posh` can be used in many terminals, therefore it is placed in
a separate role and has the same tag as `powershell` role - `powershell`. So
when you try to install any compatible shell, it will be installed alongside.

If the role is a direct dependency of another roles, then use meta
`dependencies`.
