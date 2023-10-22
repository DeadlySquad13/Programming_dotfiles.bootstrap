# My dotfiles

Configure linux workstation using Ansible.

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
