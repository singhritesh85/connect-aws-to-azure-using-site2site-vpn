module "eks_cluster" {
  source = "../aws-module"

  vpc_cidr = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr = var.public_subnet_cidr
  igw_name = var.igw_name
  vpc_name = var.vpc_name

  env = var.env[0]

###########################To Launch EC2###################################

  instance_count = var.instance_count
  provide_ami = var.provide_ami["us-east-2"]
  instance_type = var.instance_type[0]
  kms_key_id = var.kms_key_id
  name = var.name 

########################## AWS Site-to-Site VPN ############################

  ip_address_azure_vpn_gtw = var.ip_address_azure_vpn_gtw
  azure_vnet_subnet_cidr_block = var.azure_vnet_subnet_cidr_block

}
