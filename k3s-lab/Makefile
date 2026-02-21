.PHONY: all deploy prep hosts site

all: deploy prep hosts site

deploy:
	sudo bash deploy-vms.sh
	@echo "Waiting 60 seconds for VMs to boot..."
	sleep 60

prep:
	bash prep-ansible-inv.sh

hosts:
	cd ansible && ansible-playbook -i inv/lab.ini playbooks/hosts.yml -u k3slab -b

site:
	cd ansible && ansible-playbook -i inv/lab.ini playbooks/site.yml -u k3slab -b
