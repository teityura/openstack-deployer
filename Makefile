default: deploy
init: sample vault encrypt
cl: clean
cla: clean clean_all

sample:
	@if [ ! -f $(CURDIR)/group_vars/all.yml ]; then \
		cp $(CURDIR)/group_vars/all.yml.sample $(CURDIR)/group_vars/all.yml; \
	fi
	@if [ ! -f $(CURDIR)/vm_params.yml ]; then \
		cp $(CURDIR)/vm_params.yml.sample $(CURDIR)/vm_params.yml; \
	fi

vault:
	@if [ ! -f /etc/ansible/.vault_pass ]; then \
		cat /dev/urandom | base64 | fold -w 20 | head -n 1 > /etc/ansible/.vault_pass; \
	fi

encrypt:
	@if ! grep -q '^$$ANSIBLE_VAULT;' $(CURDIR)/group_vars/all.yml; then \
		ansible-vault encrypt $(CURDIR)/group_vars/all.yml; \
	fi

deploy:
	ansible-playbook create_key.yml
	ansible-playbook create_servers.yml
	ansible-playbook create_ssh_config.yml
	ansible-playbook ensure_vm_ssh.yml
	ansible-playbook setup_users.yml

clean:
	ansible-playbook delete_servers.yml
	rm -f $(CURDIR)/hosts
	rm -f $(CURDIR)/roles/ssh/vars/main.yml
	rm -rf $(CURDIR)/host_vars/

clean_all:
	@echo "Are you sure you want to delete everything? [yes/no]" && read ans; \
	if [ "$$ans" = "yes" ]; then \
		ansible-playbook delete_key.yml; \
		rm -f $(CURDIR)/vm_params.yml; \
		rm -f $(CURDIR)/group_vars/all.yml; \
		rm -f /etc/ansible/.vault_pass; \
	else \
		echo "Deletion canceled."; \
	fi
