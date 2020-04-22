data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-vpc"]
  }
}

data "aws_security_group" "private-securitygroup" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-private-securitygroup"]
  }
}

data "aws_subnet" "private-subnet" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-private-subnet"]
  }
}

data "aws_subnet" "private-subnet2" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-private-subnet2"]
  }
}


resource "aws_db_subnet_group" "rds-subnetgroup" {
  name = "${var.environment_name}-${var.user}-subnet-group"
  subnet_ids = ["${data.aws_subnet.private-subnet.id}", "${data.aws_subnet.private-subnet2.id}"]

  tags = {
        Name = "${var.environment_name}-rds-subnetgroup"
        App = "takeon"
    }
}

resource "random_string" "username" {
  length = 16
  special = false
}

resource "random_password" "password" {
  length = 32
  special = true
  override_special = "_%@"
}

resource "aws_db_instance" "RDS" {
    allocated_storage = 5
    storage_type = "gp2"
    engine = "postgres"
    engine_version = 11.4
    instance_class = "db.t3.small"
    name = "takeon${var.user}"
    username = random_string.username.result
    password = random_password.password.result
    backup_retention_period = 7
    identifier = "${var.environment_name}-${var.user}"
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.rds-subnetgroup.name
    vpc_security_group_ids = ["${data.aws_security_group.private-securitygroup.id}"]

      tags = {
        Name = "${var.environment_name}-${var.user}-RDS"
        App = "takeon"
    }
    
}
