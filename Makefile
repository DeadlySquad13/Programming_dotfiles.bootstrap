ifneq (,$(wildcard ./.env.dev))
    include .env.dev
    export
endif

# Ansible.
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

# Docker.
build-image:
	docker build . -t ${IMAGE_NAME}

start:
	docker run --name "${CONTAINER_NAME}" --detach --rm "${IMAGE_NAME}"

lint-check:
	docker exec "${CONTAINER_NAME}" pixi run --environment dev lint-check

format-check:
	docker exec "${CONTAINER_NAME}" pixi run --environment dev format-check

types-check:
	docker exec "${CONTAINER_NAME}" pixi run --environment dev types-check

order-imports-check:
	docker exec "${CONTAINER_NAME}" pixi run --environment dev order-imports-check

connect:
	docker run --name ${CONTAINER_NAME} -it ${IMAGE_NAME} --entrypoint /bin/bash

stop:
	docker stop "${CONTAINER_NAME}"

rm-all-containers:
	docker rm $(docker ps --quiet --all)
