# Terraform Config file (main.tf). This has provider block (AWS) and config for provisioning one EC2 instance resource.  

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Define tags locally
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
}

# Create a new VPC 
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = merge(
    local.default_tags, {
      Name = "Group10-${var.prefix}-VPC-acs730"
    }
  )
}

# Add provisioning of the public subnetin the default VPC
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.default_tags, {
      Name = "Group5-${var.prefix}-public-subnet-${count.index}"
    }
  )
}

# Add provisioning of the private subnet in the default VPC
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.default_tags, {
      Name = "Group10-${var.prefix}-private-subnet-${count.index}"
    }
  )
}


# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  count  = var.env == "prod" ? 1 : 0

  tags = merge(local.default_tags,
    {
      "Name" = "Group10-${var.prefix}-igw"
    }
  )
}

# Route table to route add default gateway pointing to Internet Gateway (IGW)
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  count  = var.env == "prod" ? 1 : 0
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  
  tags = {
    Name = "Group10-${var.prefix}-route-public-subnets"
  }
}



# Route table to route add default gateway pointing to NAT Gateway (NGW)
resource "aws_route_table" "private_subnets" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "Group10-${var.prefix}-route-private-subnets"
  }
}



# Associate public subnets with the custom route table
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(aws_subnet.public_subnet[*].id)
  route_table_id = aws_route_table.public_subnets[0].id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

# Associate private subnets with the custom route table
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(aws_subnet.private_subnet[*].id)
  route_table_id = aws_route_table.private_subnets.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}
