# MongoDB Cluster on AWS - Self-Hosted Replica Set (Terraform + Ansible)

3-node mongod replica set on EC2, IaC + config mgmt. Deep dive on replSet/keyfile auth/oplog/failover.

## Architecture

- VPC: 3 public subnets across AZs, IGW (no NAT) - see `infra/terraform/vpc.tf`
- 3x EC2 (t3.micro), each with its own EBS volume at `/data/db` - `ec2.tf`
- Single shared key pair for SSH to all nodes
- Security group: 27017 open cluster-internal + your IP only, 22 from your IP - `sg.tf`
- Replica set `rs0`: 1 primary + 2 secondary
- Auth: keyfile (internal cluster auth) + SCRAM user auth
- Terraform state: local only (solo/learning setup, no S3/DynamoDB backend)

## Run it

```bash
make infra       # terraform apply: VPC, EC2, SG, key pair
make inventory   # generate infra/ansible/inventory.ini from tf outputs
make keyfile     # generate mongo internal-auth keyfile (once)
make config      # ansible: install + configure mongod on all nodes
export MONGO_ROOT_PW='<strong-password>'
make init-rs     # rs.initiate() + create root user (idempotent)
make verify HOST=<mongo1_public_ip>
```

`make destroy` tears everything down.

## Verify / failover test

```bash
mongosh --host <ip> -u root -p --authenticationDatabase admin --eval "rs.status()"
```

Confirm 1 `PRIMARY` + 2 `SECONDARY`. To test failover: `sudo systemctl stop mongod` on the primary, watch a secondary get promoted from another node, then restart mongod and confirm it rejoins as `SECONDARY`.

## Notes

- Optional next step: private Route53 zone (`mongo1.mongo.internal` etc.) instead of raw IPs in `rs.initiate()` - not implemented, revisit if this becomes long-lived infra.
