# single key pair shared by all 3 nodes - fine for a single-admin cluster
resource "tls_private_key" "mongo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "mongo" {
  key_name   = "mongo-cluster-key"
  public_key = tls_private_key.mongo.public_key_openssh
}

resource "local_file" "mongo_private_key" {
  content         = tls_private_key.mongo.private_key_pem
  filename        = "${path.module}/mongo-cluster-key.pem"
  file_permission = "0600"
}

resource "aws_instance" "mongo" {
  for_each = toset(var.nodes)

  ami                    = var.ami_id
  instance_type          = var.instance_type
  # round-robins nodes across subnets/AZs, e.g. mongo1->a, mongo2->b, mongo3->c
  subnet_id              = values(aws_subnet.mongo)[index(var.nodes, each.key) % length(aws_subnet.mongo)].id
  vpc_security_group_ids = [aws_security_group.mongo.id]
  key_name               = aws_key_pair.mongo.key_name

  tags = { Name = each.key }
}

# separate data volume per node, mounted at /data/db by the ansible playbook
resource "aws_ebs_volume" "mongo_data" {
  for_each          = toset(var.nodes)
  availability_zone = aws_instance.mongo[each.key].availability_zone
  size              = 20
  type              = "gp3"
  tags              = { Name = "${each.key}-data" }
}

resource "aws_volume_attachment" "mongo_data" {
  for_each    = toset(var.nodes)
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.mongo_data[each.key].id
  instance_id = aws_instance.mongo[each.key].id
}
