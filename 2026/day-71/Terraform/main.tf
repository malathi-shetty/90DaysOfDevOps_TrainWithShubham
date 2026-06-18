resource "aws_security_group" "ansible_sg" {
  name = "ansible-lab-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = ["106.222.206.202/32"]
    cidr_blocks = [
      "${chomp(data.http.myip.response_body)}/32"
    ]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

variable "servers" {
  default = {
    web = {
      ami  = "ubuntu"
      type = "t2.micro"
    }
    app = {
      ami  = "ubuntu"
      type = "t2.micro"
    }
    db = {
      ami  = "ubuntu"
      type = "t2.micro"
    }
  }
}

resource "aws_instance" "servers" {
  for_each = var.servers

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.type

  key_name      = var.key_name
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = each.key
  }
}
