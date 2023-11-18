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

    customer_gateways = {
    IP1 = {
      bgp_asn     = 65000
      ip_address  = aws_eip.openswan.public_ip
      device_name = "some_name"
    },
#    IP2 = {
#      bgp_asn    = 65112
#      ip_address = "5.6.7.8"
#    }
  }

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

locals {
  web_name = format("%s-%s-openswan", var.project, var.environment)
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

//AWS Resource for Create EIP OpenVPN
resource "aws_eip" "openswan" {
  instance = aws_instance.openswan.id
  vpc      = true
  tags = merge(local.common_tags, {
    Name = format("%s-EIP", local.web_name)
  })
}
