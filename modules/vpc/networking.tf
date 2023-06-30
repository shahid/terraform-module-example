resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  #  instance_tenancy = "${var.tenancy}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_name}"
  }
}

######################
resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "public_eks_subnets" {
 count      = length(var.public_subnet_eks_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.public_subnet_eks_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
   "kubernetes.io/cluster/eks-development-example" = "shared"
   "kubernetes.io/role/elb"                           = 1
 }
}

resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
  
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "private_eks_subnets" {
 count      = length(var.private_subnet_eks_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_eks_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Private Subnet ${count.index + 1}"
   "kubernetes.io/cluster/eks-development-example" = "shared"
   "kubernetes.io/role/elb"                           = 1
 }
}

resource "aws_subnet" "private_rds_subnets" {
 count      = length(var.private_subnet_rds_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.private_subnet_rds_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.gw_name}"
  }
}
resource "aws_eip" "nat_eip" {
  #vpc       = true
  #domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  #count = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = "${element(aws_subnet.public_subnets.*.id, 0)}"
  #subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.nat_name}"
  }
}

/* Route table associations */
resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_subnet_eks_asso" {
 count = length(var.public_subnet_eks_cidrs)
 subnet_id      = element(aws_subnet.public_eks_subnets[*].id, count.index)
 route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_subnet_asso" {
 count = length(var.private_subnet_cidrs)
 subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
 route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_subnet_eks_asso" {
 count = length(var.private_subnet_eks_cidrs)
 subnet_id      = element(aws_subnet.private_eks_subnets[*].id, count.index)
 route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_subnet_rds_asso" {
 count = length(var.private_subnet_rds_cidrs)
 subnet_id      = element(aws_subnet.private_rds_subnets[*].id, count.index)
 route_table_id = aws_route_table.private.id
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.rtbprivate_name}"
  }
}
/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.rtbpublic_name}"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, 0)}"
}
