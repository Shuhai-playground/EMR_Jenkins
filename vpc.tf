# VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
      "Name" = "main"
    }
  
}

# internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
      "Name" = "igw"
    }
  
}

# private subenets
resource "aws_subnet" "private_us_east_1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_cidrblock[0]
    availability_zone = var.av_zone[0]

    tags = {
      "Name" = "private-${var.av_zone[0]}"
      "kubernetes.io/role/internal-elb"="1" # private elb
      "kubernetes.io/cluster/demo" ="owned" # under cluster demo
    }

}

resource "aws_subnet" "private_us_east_1b" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_cidrblock[1]
    availability_zone = var.av_zone[1]

    tags = {
      "Name" = "private-${var.av_zone[1]}"
      "kubernetes.io/role/internal-elb"="1" # private elb
      "kubernetes.io/cluster/demo" ="owned" # under cluster demo
    }

}

# Public subnets
resource "aws_subnet" "public_us_east_1a" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_cidrblock[0]
    availability_zone = var.av_zone[0]
    map_public_ip_on_launch = true

    tags = {
      "Name" = "public-${var.av_zone[0]}"
      "kubernetes.io/role/elb"="1" # public elb
      "kubernetes.io/cluster/demo" ="owned" # under cluster demo
    }

}

resource "aws_subnet" "public_us_east_1b" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_cidrblock[1]
    availability_zone = var.av_zone[1]
    map_public_ip_on_launch = true

    tags = {
      "Name" = "public-${var.av_zone[1]}"
      "kubernetes.io/role/elb"="1" # public elb
      "kubernetes.io/cluster/demo" ="owned" # under cluster demo
    }

}

resource "aws_eip" "eip" {
    vpc = true
    count=2

    tags={
        "Name"="EIP-${count.index + 1}"
    }
  
}

resource "aws_nat_gateway" "nat" {
    count=2
    subnet_id = element([aws_subnet.public_us_east_1a.id,aws_subnet.public_us_east_1b.id],count.index)
    allocation_id = element(aws_eip.eip.*.id, count.index)

    depends_on = [
      aws_internet_gateway.igw
    ]
  
}

resource "aws_route_table" "private" {
    count=2
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
    }

    tags = {
      "Name" = "private"
    }
  
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags={
        "Name"="Public"
    }
  
}

# route private subnets
resource "aws_route_table_association" "private_us_east_1a" {
    subnet_id = aws_subnet.private_us_east_1a.id
    route_table_id = aws_route_table.private[0].id
  
}

resource "aws_route_table_association" "private_us_east_1b" {
    subnet_id = aws_subnet.private_us_east_1b.id
    route_table_id = aws_route_table.private[1].id
  
}


# route public subnets
resource "aws_route_table_association" "public_us_east_1a" {
    subnet_id = aws_subnet.public_us_east_1a.id
    route_table_id = aws_route_table.public.id

 
}

resource "aws_route_table_association" "public_us_east_1b" {
    subnet_id = aws_subnet.public_us_east_1b.id
    route_table_id = aws_route_table.public.id
  
}