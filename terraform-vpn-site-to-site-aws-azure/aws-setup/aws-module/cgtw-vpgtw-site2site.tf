########################################## Customer Gateway ###############################################

resource "aws_customer_gateway" "customer_gtw" {
  bgp_asn    = 65000
  ip_address = var.ip_address_azure_vpn_gtw               ### Public IP Address of the Azure VPN Gateway
  type       = "ipsec.1"

  tags = {
    Name = "${var.vpc_name}-customer-gateway"
  }
}

########################################## virtual private gateway ########################################

resource "aws_vpn_gateway" "vpn_gtw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "${var.vpc_name}-virtual-private-gateway"
  }
}

######################################### AWS Site-to-Site VPN ############################################

resource "aws_vpn_connection" "site2site_vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gtw.id
  customer_gateway_id = aws_customer_gateway.customer_gtw.id
  type                = "ipsec.1"
  static_routes_only  = true
  
  tags = {
    Name = "${var.vpc_name}-site2site-vpn"
  }
}


resource "aws_vpn_connection_route" "site2site_vpn_onnection" {
  destination_cidr_block = var.azure_vnet_subnet_cidr_block    ### Provide Azure VNet Subnet CIDR
  vpn_connection_id      = aws_vpn_connection.site2site_vpn.id
}
