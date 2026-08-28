.PHONY: infra inventory keyfile config init-rs verify destroy

infra:      ## terraform init + apply (VPC, EC2, SG, key pair)
	cd infra/terraform && terraform init && terraform apply -auto-approve

inventory:  ## regenerate infra/ansible/inventory.ini from terraform outputs
	./infra/ansible/generate_inventory.sh

keyfile:    ## generate mongo internal-auth keyfile (run once, before `make config`)
	mkdir -p infra/ansible/files
	openssl rand -base64 756 > infra/ansible/files/mongo-keyfile
	chmod 400 infra/ansible/files/mongo-keyfile

config:     ## install mongod + apply config to every node
	ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml

init-rs:    ## one-time: rs.initiate() + create root user (needs MONGO_ROOT_PW env var)
	./init_replica_set.sh

verify:     ## check replica set status; usage: make verify HOST=<public-ip>
	mongosh --host $(HOST) -u root -p --authenticationDatabase admin --eval "rs.status()"

destroy:    ## tear down all AWS resources
	cd infra/terraform && terraform destroy -auto-approve
