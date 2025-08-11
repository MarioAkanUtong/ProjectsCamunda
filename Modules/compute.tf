variable "instance_type" {}
variable "ami_id" {}
variable "subnet_id" {}
variable "env" {}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  tags = {
    Name = "${var.env}-app-instance"
  }
}
