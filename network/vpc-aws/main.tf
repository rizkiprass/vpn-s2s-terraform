provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"
  # insert the 14 required variables here
  name                             = format("%s-%s-VPC", var.project, var.environment)
  cidr                             = var.cidr
  enable_dns_hostnames             = true
  enable_dhcp_options              = true
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]
  azs                              = ["${var.region}a", "${var.region}b"]
  public_subnets                   = [var.Public_Subnet_AZA_1, var.Public_Subnet_AZB_1]
  private_subnets                  = [var.App_Subnet_AZA, var.App_Subnet_AZB]
  # intra_subnets                    = [var.Data_Subnet_AZ1, var.Data_Subnet_AZ2] //this is subnet only route to local vpc
  database_subnets = [var.Data_Subnet_AZA, var.Data_Subnet_AZB] // subnet db route to nat
  # Nat Gateway
  enable_nat_gateway = true
  single_nat_gateway = true #if true, nat gateway only create one
  # Reuse NAT IPs
  reuse_nat_ips         = true                 # <= if true, Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids   = [aws_eip.eip-nat.id] #attach eip from manual create eip
  public_subnet_suffix  = "public"
  private_subnet_suffix = "private"
  intra_subnet_suffix   = "db"
  #  intra_subnet_suffix   = "data"

  #Virtual Private Gateway
  enable_vpn_gateway = true


  tags = local.common_tags
  #  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  #  enable_flow_log                      = true
  #  create_flow_log_cloudwatch_log_group = true
  #  create_flow_log_cloudwatch_iam_role  = true
  #  flow_log_max_aggregation_interval    = 60
  #  flow_log_cloudwatch_log_group_kms_key_id = module.kms-cwatch-flowlogs-kms.key_arn



  #  //tags for vpc flow logs
  #  vpc_flow_log_tags = {
  #    Name = format("%s-%s-vpc-flowlogs", var.project, var.environment)
  #  }
}

//eip for nat
resource "aws_eip" "eip-nat" {
  vpc = true
  tags = merge(local.common_tags, {
    Name = format("%s-%s-EIP", var.project, var.environment)
  })
}

#resource "aws_eip" "eip-nat2-sandbox" {
#  vpc = true
#  tags = merge(local.common_tags, {
#    Name = format("%s-production-EIP2", var.project)
#  })
#}

#resource "aws_eip" "eip-jenkins" {
#  vpc      = true
#  instance = aws_instance.jenkins-app.id
#  tags = merge(local.common_tags, {
#    Name = format("%s-production-EIP-jenkins", var.project)
#  })
#}

#

#//Create a db subnet with routing to nat
#resource "aws_subnet" "subnet-db-1a" {
#  vpc_id            = module.vpc.vpc_id
#  cidr_block        = var.Data_Subnet_AZA
#  availability_zone = format("%sa", var.aws_region)
#
#  tags = merge(local.common_tags,
#    {
#      Name = format("%s-%s-data-subnet-3a", var.project, var.environment) //
#  })
#}
#
#resource "aws_subnet" "subnet-db-1b" {
#  vpc_id            = module.vpc.vpc_id
#  cidr_block        = var.Data_Subnet_AZB
#  availability_zone = format("%sb", var.aws_region)
#
#  tags = merge(local.common_tags,
#    {
#      Name = format("%s-%s-data-subnet-3b", var.project, var.environment) //
#  })
#}
#
#resource "aws_route_table" "data-rt" {
#  vpc_id = module.vpc.vpc_id
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = module.vpc.natgw_ids[0]
#  }
#
#  tags = merge(local.common_tags, {
#    Name = format("%s-%s-data-rt", var.project, var.environment)
#  })
#}
#
#resource "aws_route_table_association" "rt-subnet-assoc-data-3a" {
#  subnet_id      = aws_subnet.subnet-db-1a.id
#  route_table_id = aws_route_table.data-rt.id
#}
#
#//Create a app subnet
#resource "aws_subnet" "subnet-app-1a" {
#  vpc_id            = module.vpc.vpc_id
#  cidr_block        = var.App_Subnet_AZA
#  availability_zone = format("%sa", var.aws_region)
#
#  tags = merge(local.common_tags,
#    {
#      Name = format("%s-%s-app-subnet-3a", var.project, var.environment) //
#  })
#}
#
#resource "aws_subnet" "subnet-app-1b" {
#  vpc_id            = module.vpc.vpc_id
#  cidr_block        = var.App_Subnet_AZB
#  availability_zone = format("%sb", var.aws_region)
#
#  tags = merge(local.common_tags,
#    {
#      Name = format("%s-%s-app-subnet-3b", var.project, var.environment) //
#  })
#}
#
#resource "aws_route_table" "app-rt" {
#  vpc_id = module.vpc.vpc_id
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = module.vpc.natgw_ids[0]
#  }
#
#  tags = merge(local.common_tags, {
#    Name = format("%s-%s-app-rt", var.project, var.environment)
#  })
#}
#
#resource "aws_route_table_association" "rt-subnet-assoc-app-3a" {
#  subnet_id      = aws_subnet.subnet-app-1a.id
#  route_table_id = aws_route_table.app-rt.id
#}

module "vpn_gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "~> 3.0"

  vpc_id                  = module.vpc.vpc_id
  vpn_gateway_id          = module.vpc.vgw_id
  customer_gateway_id     = "cgw-056fa9192f137b85c"

  vpn_connection_static_routes_only = true
  vpn_connection_static_routes_destinations = [] #fill dest routes

  # precalculated length of module variable vpc_subnet_route_table_ids
  vpc_subnet_route_table_count = 3
  vpc_subnet_route_table_ids   = module.vpc.private_route_table_ids

  # tunnel inside cidr & preshared keys (optional)
#  tunnel1_inside_cidr   = var.custom_tunnel1_inside_cidr
#  tunnel2_inside_cidr   = var.custom_tunnel2_inside_cidr
#  tunnel1_preshared_key = var.custom_tunnel1_preshared_key
#  tunnel2_preshared_key = var.custom_tunnel2_preshared_key
}

locals {
  web_name = format("%s-%s-server-aws1", var.project, var.environment)
}

//Server Private web
resource "aws_instance" "openswan" {
  ami                         = "ami-0fa1ca9559f1892ec"
  instance_type               = "t3.medium"
  associate_public_ip_address = "true"
  key_name                    = "testing-key"
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.ssm-profile.name
  user_data                   = file("openswan.sh")
  source_dest_check           = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  vpc_security_group_ids = [aws_security_group.web-app-sg.id]
  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    iops                  = 3000
    encrypted             = true
    delete_on_termination = true
    tags = merge(local.common_tags, {
      Name = format("%s-ebs", local.web_name)
    })
  }

  lifecycle {

  }

  tags = merge(local.common_tags, {
    Name   = local.web_name,
    OS     = "Centos",
    Backup = "DailyBackup" # TODO: Set Backup Rules
  })
}
