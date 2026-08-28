variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "ami_id" {
  type        = string
  description = "Amazon Linux 2023 AMI id for target region"
}

variable "my_ip" {
  type        = string
  description = "Your public IP in CIDR form, e.g. 1.2.3.4/32, for mongosh access"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  type    = map(string)
  default = {
    a = "10.0.1.0/24"
    b = "10.0.2.0/24"
    c = "10.0.3.0/24"
  }
}

variable "nodes" {
  type    = list(string)
  default = ["mongo1", "mongo2", "mongo3"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
