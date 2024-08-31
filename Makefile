run:
	ANSIBLE_CONFIG=ansible.cfg ./bin/dot-bootstrap

run-taskserver:
	ANSIBLE_CONFIG=ansible.cfg ansible-playbook ./taskserver.yml

# TODO: Move to snakemake and add optional param for host.
vault-edit-salt .vault_pass.py ./group_vars/salt/vault:
	ANSIBLE_CONFIG=ansible.cfg ansible-vault edit --vault-password-file ./.vault_pass.py ./group_vars/salt/vault

vault-edit-MikhailLermontov .vault_pass.py ./host_vars/MikhailLermontov/vault:
	ANSIBLE_CONFIG=ansible.cfg ansible-vault edit --vault-password-file ./.vault_pass.py ./host_vars/MikhailLermontov/vault

install requirements.yml:
	ansible-galaxy install -r requirements.yml

# TODO: Move to snakemake and add optional param for host.
facts:
	ANSIBLE_CONFIG=ansible.cfg ansible localhost -m ansible.builtin.setup

facts-MikhailLermontov:
	ANSIBLE_CONFIG=ansible.cfg ansible MikhailLermontov -m ansible.builtin.setup

config:
	ansible-config dump
