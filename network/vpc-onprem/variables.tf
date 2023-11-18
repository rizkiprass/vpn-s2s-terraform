variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

// Tag
variable "Birthday" {
  default = "26-01-2022"
}

variable "Backup" {
  default = "BackupDaily"
}
variable "region" {
  default = "us-east-1"
}

variable "cidr" {
  default = "192.168.0.0/16"
}

variable "Public_Subnet_AZA_1" {
  default = "192.168.0.0/24"
}

variable "Public_Subnet_AZB_1" {
  default = "192.168.1.0/24"
}

variable "App_Subnet_AZA" {
  default = "192.168.10.0/24"
}

variable "App_Subnet_AZB" {
  default = "192.168.11.0/24"
}

variable "Data_Subnet_AZA" {
  default = "192.168.20.0/24"
}

variable "Data_Subnet_AZB" {
  default = "192.168.21.0/24"
}

#Tagging Common
variable "environment" {
  default = "dev"
}

variable "project" {
  default = "onprem"
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Terraform   = "Yes"
  }
}

#key
variable "key-bastion-inject" {
  default = "bastion-inject"
}
