# used by init_replica_set.sh for rs.initiate() member hosts
output "mongo_private_ips" {
  value = { for k, v in aws_instance.mongo : k => v.private_ip }
}

# used by generate_inventory.sh to build the ansible inventory
output "mongo_public_ips" {
  value = { for k, v in aws_instance.mongo : k => v.public_ip }
}

output "security_group_id" {
  value = aws_security_group.mongo.id
}

output "mongo_instance_ids" {
  value = { for k, v in aws_instance.mongo : k => v.id }
}

output "ssh_private_key_path" {
  value = local_file.mongo_private_key.filename
}

output "ssh_key_name" {
  value = aws_key_pair.mongo.key_name
}

output "region" {
  value = var.region
}
