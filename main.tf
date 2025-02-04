provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "LearnTerraform"
      Lesson = "ManageAWSRDSInstances"
    }
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = ">=2.77.0"

  name                 = "education_vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "education" {
  name       = "education_subnet_group"
  subnet_ids = module.vpc.public_subnets
  description = "Security group for education db instance"

  tags = {
    Name = "education_subnet_group"
  }
}

resource "aws_security_group" "rds" {
  name   = "education_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "education_rds_security_group"
  }
}

resource "aws_db_parameter_group" "education" {
  name   = "education"
  family = "postgres12"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "education_db_parameter_group"
  }
}

resource "aws_db_instance" "education" {
  identifier             = "education-db-instance"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "12.8"
  username               = "edu"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.education.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
