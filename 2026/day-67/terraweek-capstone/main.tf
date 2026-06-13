module "vpc" {
  source = "./modules/vpc"

  cidr               = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr

  environment  = var.environment
  project_name = var.project_name
}

module "security_group" {
  source = "./modules/security-group"

  vpc_id = module.vpc.vpc_id

  ingress_ports = var.ingress_ports

  environment  = var.environment
  project_name = var.project_name
}

module "ec2" {
  source = "./modules/ec2-instance"

  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.subnet_id
  security_group_ids = [module.security_group.sg_id]

  environment  = var.environment
  project_name = var.project_name
}