resource "aws_security_group" "ansible_sg" {
  name = "ansible-lab-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["106.222.211.42/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  server_names = [
    "web-server",
    "app-server",
    "db-server"
  ]
}

resource "aws_instance" "servers" {
  count         = length(local.server_names)

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.ansible_sg.id
  ]

  tags = {
    Name = local.server_names[count.index]
  }
}