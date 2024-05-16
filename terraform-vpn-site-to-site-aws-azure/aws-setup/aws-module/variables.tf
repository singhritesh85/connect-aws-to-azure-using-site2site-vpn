variable "vpc_cidr"{

}

variable "private_subnet_cidr"{

}

variable "public_subnet_cidr"{

}

variable "igw_name" {

}

variable "vpc_name" {

}

variable "env" {

}

data aws_availability_zones azs {

}

############################## variables to launch EC2 ###################################

variable "instance_count" {

}

variable "provide_ami" {

}

variable "instance_type" {

}

variable "kms_key_id" {

}

variable "name" {

}

############################### Site to Site VPN #########################################

variable "ip_address_azure_vpn_gtw" {

}

variable "azure_vnet_subnet_cidr_block" {

}

