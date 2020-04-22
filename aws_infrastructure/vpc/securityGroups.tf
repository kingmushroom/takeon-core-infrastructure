# Security group for the bastion instance to allow local update
resource "aws_security_group" "bastion-securitygroup" {
    name = "${var.environment_name}-bastion-securitygroup"
    vpc_id = aws_vpc.vpc.id
  
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "TCP"
        cidr_blocks =[var.my_ip]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port = 5432
        to_port = 5432
        protocol = "TCP"
        cidr_blocks = [var.cidr_private]
    }

    egress {
        from_port = 5432
        to_port = 5432
        protocol = "TCP"
        cidr_blocks = [var.cidr_private2]
    }

    egress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [var.cidr_private]
    }

    egress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [var.cidr_private2]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }

    tags = {
        Name = "${var.environment_name}-bastion-securitygroup"
        App = "takeon"
    }
}

# private security group
resource "aws_security_group" "private-securitygroup" {
    name = "${var.environment_name}-private-securitygroup"
    vpc_id = aws_vpc.vpc.id
    timeouts {
        delete = "40m"
    }
    # Ingress ruless
        ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.cidr_private]
    }

    # To access database from the Bastion
        ingress {
        from_port = 5432
        to_port = 5432
        protocol = "TCP"
        security_groups = [aws_security_group.bastion-securitygroup.id]
    }

    # Egress rules
    egress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.cidr_private]
    }

    egress {
        to_port = 443
        from_port = 443
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = ["pl-7ca54015"]
        description = "Allow access to s3 using prefix list id"
    }


    tags = {
        Name = "${var.environment_name}-private-securitygroup"
        App = "takeon"
    }
}

# Rules that depend on other groups must be added after creation
resource "aws_security_group_rule" "private-securitygroup-Ingress" {
        type = "ingress"
        from_port = 5432
        to_port = 5432
        protocol = "TCP"
        source_security_group_id = aws_security_group.public-securitygroup.id
        security_group_id = aws_security_group.private-securitygroup.id
}

resource "aws_security_group_rule" "private-securitygroup-Egress" {
        type = "egress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        source_security_group_id = aws_security_group.public-securitygroup.id
        security_group_id = aws_security_group.private-securitygroup.id
}

resource "aws_security_group_rule" "private-securitygroup-Ingress-Self" {
        type = "ingress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        source_security_group_id = aws_security_group.private-securitygroup.id
        security_group_id = aws_security_group.private-securitygroup.id
}

resource "aws_security_group_rule" "private-securitygroup-Egress-Self" {
        type = "egress"
        from_port = 0
        to_port = 0
        protocol = "-1"
        source_security_group_id = aws_security_group.private-securitygroup.id
        security_group_id = aws_security_group.private-securitygroup.id
}

resource "aws_security_group_rule" "private-securitygroup-bastion" {
        type = "ingress"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        source_security_group_id = aws_security_group.bastion-securitygroup.id
        security_group_id = aws_security_group.private-securitygroup.id
}

# public Security Group
resource "aws_security_group" "public-securitygroup" {
  name = "${var.environment_name}-public-securitygroup"
  vpc_id = aws_vpc.vpc.id

  # Ingress rules
    ingress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = [var.my_ip]
    }


    ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      security_groups = [aws_security_group.bastion-securitygroup.id]
    }

    ingress {
      from_port = 3389
      to_port = 3389
      protocol = "TCP"
      cidr_blocks = [var.my_ip]
    }

    ingress {
      from_port = 443
      to_port = 443
      protocol = "TCP"
      cidr_blocks = [var.my_ip]
    }



    # Egress rules
    egress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = [var.my_ip]
    }

    egress {
      from_port = 443
      to_port = 443
      protocol = "TCP"
      cidr_blocks = [var.my_ip]
    }


    tags ={
        Name = "${var.environment_name}-public-securitygroup"
        App = "takeon"
    }
}

resource "aws_security_group_rule" "public-securitygroup-Ingress" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    source_security_group_id = aws_security_group.private-securitygroup.id
    security_group_id = aws_security_group.public-securitygroup.id
}

resource "aws_security_group_rule" "public-securitygroup-Egress" {
    type = "egress"
    from_port = 5432
    to_port = 5432
    protocol = "TCP"
    source_security_group_id = aws_security_group.private-securitygroup.id
    security_group_id = aws_security_group.public-securitygroup.id
}

resource "aws_security_group_rule" "public-securitygroup-Ingress-Self" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    source_security_group_id = aws_security_group.public-securitygroup.id
    security_group_id = aws_security_group.public-securitygroup.id
}

resource "aws_security_group_rule" "public-securitygroup-Egress-Self" {
    type = "egress"
    from_port = 80
    to_port = 80
    protocol = "-1"
    source_security_group_id = aws_security_group.public-securitygroup.id
    security_group_id = aws_security_group.public-securitygroup.id
}

# Endpoint security group to allow lambdas and api to interact with sqs

resource "aws_security_group" "sqs-endpoint" {
    name = "${var.environment_name}-endpoint-securitygroup"
    vpc_id = aws_vpc.vpc.id
  
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group_rule" "endpoint-securitygroup-Egress-privategroup" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    source_security_group_id = aws_security_group.sqs-endpoint.id
    security_group_id = aws_security_group.private-securitygroup.id
}




