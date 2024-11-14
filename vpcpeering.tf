
# Create the VPC Peering Connection
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id        = aws_vpc.publicvpc.id
  peer_vpc_id   = aws_vpc.main.id
  auto_accept   = true
  tags = {
    Name = "publicvpc-peering"
  }
}

# Add a route in the publicvpc to route traffic to the existing VPC
resource "aws_route" "peering_route_publicvpc" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "10.0.0.0/16"  # Adjust this to the CIDR of your existing VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Add a route in the existing VPC's route table (if required)
# You need to modify the route table of your existing VPC to route traffic to the new VPC
resource "aws_route" "peering_route_existing_vpc" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "11.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}
