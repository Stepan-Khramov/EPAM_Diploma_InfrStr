# ========== Provider ==============================================
# ==================================================================
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 3.27"
#     }
#   }

#   required_version = ">= 0.14.9"
# }

provider "aws" {
  profile = "default"
  region  = var.region  
  }

# ========== VPC ===================================================
# ==================================================================
resource "aws_vpc" "vpc-01" {
  cidr_block = "10.10.0.0/16"
  instance_tenancy = "default"
#   enable_nat_gateway   = true
#   single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "EPAM_Diploma_vpc-01"
  }
}

# ========== Subnets ===============================================
# ==================================================================
resource "aws_subnet" "subnet-01" {
  vpc_id = aws_vpc.vpc-01.id
  cidr_block = "10.10.10.0/24"
  availability_zone = "eu-west-2a"
  
  tags = {
    Name = "EPAM_Diploma_subnet-01"
    }
  }

resource "aws_subnet" "subnet-02" {
  vpc_id = aws_vpc.vpc-01.id
  cidr_block = "10.10.20.0/24"
  availability_zone = "eu-west-2b"
  
  tags = {
    Name = "EPAM_Diploma_subnet-02"
    }
  }

resource "aws_subnet" "subnet-03" {
  vpc_id = aws_vpc.vpc-01.id
  cidr_block = "10.10.30.0/24"
  availability_zone = "eu-west-2c"
  
  tags = {
    Name = "EPAM_Diploma_subnet-03"
    }
  }

resource "aws_db_subnet_group" "diploma_subnet_group" {
  name       = "diploma-subnet-group"
  subnet_ids = [aws_subnet.subnet-01.id, aws_subnet.subnet-02.id, aws_subnet.subnet-03.id]

  tags = {
    Name = "EPAM_Diploma_db_subnet_group"
  }
}

# ========== Security groups =======================================
# ==================================================================
resource "aws_security_group" "diploma-wrkr-grp-mgmt-1" {
  name_prefix = "diploma-wrkr-grp-mgmt-1"
  vpc_id      = aws_vpc.vpc-01.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.10.0.0/16",
    ]
  }
}

resource "aws_security_group" "diploma-wrkr-grp-mgmt-2" {
  name_prefix = "diploma-wrkr-grp-mgmt-2"
  vpc_id      = aws_vpc.vpc-01.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "diploma_all_wrkr_mgmt" {
  name_prefix = "diploma_all_wrkr_mgmt"
  vpc_id      = aws_vpc.vpc-01.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.10.0.0/16",
      "172.16.0.0/16",
      "192.168.0.0/16",
    ]
  }
}

# ========== EKS cluster ===========================================
# ==================================================================
module "diploma_eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "diploma_eks_cluster"
  cluster_version = "1.20"
  subnets         = [aws_subnet.subnet-01.id, aws_subnet.subnet-02.id, aws_subnet.subnet-03.id]

  tags = {
    Environment = "training"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = aws_vpc.vpc-01.id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.micro"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.diploma-wrkr-grp-mgmt-1.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.micro"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.diploma-wrkr-grp-mgmt-2.id]
      asg_desired_capacity          = 1
    },
  ]
}

data "aws_eks_cluster" "diploma_cluster" {
  name = module.diploma_eks.cluster_id
}

data "aws_eks_cluster_auth" "diploma_cluster" {
  name = module.diploma_eks.cluster_id
}