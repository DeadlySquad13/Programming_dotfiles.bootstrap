run:
	ANSIBLE_CONFIG=ansible.cfg ./bin/dot-bootstrap

# TODO: Add optional param for host.
vault-edit .vault_pass.py ./group_vars/salt/vault:
	ANSIBLE_CONFIG=ansible.cfg ansible-vault edit --vault-password-file ./.vault_pass.py ./group_vars/salt/vault