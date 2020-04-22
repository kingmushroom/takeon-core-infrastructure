# Defining the VPC to be used
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.environment_name}-vpc"
        App = "takeon"
        "kubernetes.io/cluster/eks-cluster" = "shared"
    }
}

# Setting elastic IP
resource "aws_eip" "eip" {
    vpc = true

    tags = {
        Name = "${var.environment_name}-eip"
        App = "takeon"
    }
}

# Defining NAT Gateway - Must be associated with public subnet
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public-subnet.id

    tags = {
        Name = "${var.environment_name}-nat"
        App = "takeon"
    }
}

# Defining Internet gateway - allows vpc to access internet
resource "aws_internet_gateway" "ig" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "${var.environment_name}-ig"
        App = "takeon"
    }
}

# Defining main route table, associated with private subnet and nat gateway
resource "aws_route_table" "main-routetable" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "${var.environment_name}-main-routetable"
        App = "takeon"
    }
}

# Associating private subnet
resource "aws_route_table_association" "main-routetable" {
    subnet_id = aws_subnet.private-subnet.id
    route_table_id = aws_route_table.main-routetable.id
}


# Defining secondary route table, associated with public subnet and internet gateway

resource "aws_route_table" "secondary-routetable" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ig.id
    }

    tags = {
        Name = "${var.environment_name}-secondary-routetable"
        App = "takeon"
    }
}

# Associating public subnet
resource "aws_route_table_association" "secondary-routetable" {
    subnet_id = aws_subnet.public-subnet.id
    route_table_id = aws_route_table.secondary-routetable.id
}

# Creating endpoint to allow vpc to connect to S3
resource "aws_vpc_endpoint" "takeon-s3-endpoint" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.eu-west-2.s3"

  tags = {
        Name = "${var.environment_name}-s3-endpoint"
        App = "takeon"
    }
}

resource "aws_vpc_endpoint_route_table_association" "s3-route-association" {
  route_table_id  = aws_route_table.main-routetable.id
  vpc_endpoint_id = aws_vpc_endpoint.takeon-s3-endpoint.id
}

resource "aws_vpc_endpoint" "takeon-sqs-endpoint" {
  vpc_id = aws_vpc.vpc.id
  service_name = "com.amazonaws.eu-west-2.sqs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.sqs-endpoint.id]
  
  subnet_ids = [aws_subnet.public-subnet.id, aws_subnet.private-subnet2.id]
    tags = {
        Name = "${var.environment_name}-sqs-endpoint"
        App = "takeon"
    }
}

# Defining subnets, public and private determined by route tables, must exist in different availability zones
resource "aws_subnet" "public-subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_public
    availability_zone = ""

    tags = {
        App = "takeon"
        Name = "${var.environment_name}-public-subnet"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/eks-cluster" = "shared"
    }
}

resource "aws_subnet" "public-subnet2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_public2
    availability_zone = ""

    tags = {
        Name = "${var.environment_name}-public-subnet2"
        App = "takeon"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/eks-cluster" = "shared"
    }
}

resource "aws_subnet" "private-subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_private
    availability_zone = "eu-west-2a"
    timeouts {
        delete = "40m"
    }
    tags = {
        Name = "${var.environment_name}-private-subnet"
        App = "takeon"
        "kubernetes.io/cluster/eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_subnet" "private-subnet2" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cidr_private2
    availability_zone = "eu-west-2b"
    timeouts {
        delete = "40m"
    }
    tags = {
        Name = "${var.environment_name}-private-subnet2"
        App = "takeon"
        "kubernetes.io/cluster/eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}
