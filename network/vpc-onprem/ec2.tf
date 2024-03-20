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