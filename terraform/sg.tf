resource "aws_security_group" "mongo" {
  name_prefix = "mongo-cluster-"
  vpc_id      = aws_vpc.mongo.id

  ingress {
    description = "cluster members talk to each other"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    self        = true # any resource with this SG attached, not just other mongo nodes
  }

  ingress {
    description = "mongosh access from admin machine"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SSH access from admin machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mongo-cluster-sg" }
}
