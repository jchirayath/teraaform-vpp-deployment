provider "aws" {
  region     = "us-east-2"
  shared_credentials_file = "/home/a/.aws/credentials"
}

#VPC

resource "aws_vpc" "VPPTest" {
  cidr_block                       = "192.1.0.0/16"
  instance_tenancy                 = "dedicated"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags = {
    Name = "VPPTest"
  }
}

#SUBNETS

resource "aws_subnet" "VPP-Management" {
  vpc_id            = aws_vpc.VPPTest.id
  cidr_block        = "192.1.0.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "VPP-Management"
  }
}

resource "aws_subnet" "VPP-Eastwest" {
  vpc_id            = aws_vpc.VPPTest.id
  cidr_block        = "192.1.2.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "VPP-Eastwest"
  }
}

resource "aws_subnet" "VPP-Westnet" {
  vpc_id                          = aws_vpc.VPPTest.id
  cidr_block                      = "192.1.3.0/24"
  availability_zone               = "us-east-2a"
  tags = {
    Name = "VPP-Westnet"
  }
}

resource "aws_subnet" "VPP-Eastnet" {
  vpc_id                          = aws_vpc.VPPTest.id
  cidr_block                      = "192.1.4.0/24"
  availability_zone               = "us-east-2a"
  tags = {
    Name = "VPP-Eastnet"
  }
}

#INTERNET GATEWAY

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.VPPTest.id
  tags = {
    Name = "main"
  }
}

#SECURITY GROUP

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.VPPTest.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = {
    Name = "allow_all"
  }

}

#INSTANCE WITH VPP CREATED BY

resource "aws_instance" "VPP-West" {
  # on us-east-2
  # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type - ami-07c1207a9d40bc3bd (64-bit x86)
  ami                    = "ami-07c1207a9d40bc3bd"
  #instance_type          = "m5d.metal"
  instance_type          = "m5.xlarge"
  key_name               = "VPP_VPPTest"
  network_interface {
    network_interface_id = aws_network_interface.VPP-WestAdmin.id
    device_index         = 0
  }
  availability_zone = "us-east-2a"
  tags = {
    Name = "VPP-West"
  }
}

resource "aws_instance" "VPP-East" {
  # on us-east-2
  # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type - ami-07c1207a9d40bc3bd (64-bit x86)
  ami                    = "ami-07c1207a9d40bc3bd"
  #instance_type          = "m5d.metal"
  instance_type          = "m5.xlarge"
  key_name               = "VPP_VPPTest"
  availability_zone = "us-east-2a"
  network_interface {
    network_interface_id = aws_network_interface.VPP-EastAdmin.id
    device_index         = 0
  }
  tags = {
    Name = "VPP-East"
  }
}

#NETWORK INTERFACES

resource "aws_network_interface" "VPP-WestAdmin" {
  subnet_id = aws_subnet.VPP-Management.id

  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
}

resource "aws_network_interface" "VPP-WestEth1" {
  subnet_id = aws_subnet.VPP-Eastwest.id

  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  attachment {
    instance     = aws_instance.VPP-West.id
    device_index = 2
  }
}

resource "aws_network_interface" "VPP-WestEth0" {
  subnet_id = aws_subnet.VPP-Westnet.id

  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  attachment {
    instance     = aws_instance.VPP-West.id
    device_index = 3
  }
}

resource "aws_network_interface" "VPP-EastAdmin" {
  subnet_id = aws_subnet.VPP-Management.id

  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
}

resource "aws_network_interface" "VPP-EastEth1" {
  subnet_id = aws_subnet.VPP-Eastwest.id

  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  attachment {
    instance     = aws_instance.VPP-East.id
    device_index = 2
  }
}

resource "aws_network_interface" "VPP-EastEth0" {
  subnet_id = aws_subnet.VPP-Eastnet.id

  security_groups   = [aws_security_group.allow_all.id]
  source_dest_check = false
  attachment {
    instance     = aws_instance.VPP-East.id
    device_index = 3
  }
}

#ASSIGN EIP

resource "aws_eip" "IPEast" {
 network_interface = aws_network_interface.VPP-EastAdmin.id
 vpc = true
}

resource "aws_eip" "IPWest" {
 network_interface = aws_network_interface.VPP-WestAdmin.id
 vpc = true
}
