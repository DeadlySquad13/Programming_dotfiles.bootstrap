install: requirements.yml
	ansible-galaxy install -r requirements.yml

facts:
	ansible localhost -m ansible.builtin.setup
