# Set Provider as AWS and region
provider "aws" {
    region = "${var.aws_region}"
    version = "2.31.0"
}