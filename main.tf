//define the region in which you are creating the EC2
provider "aws" {
  region = "ap-south-1"
}

//define the VPC
resource "aws_vpc" "CustomVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "CustomVPC"
  }

}

//define the subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.CustomVPC.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet"
  }
}

//define the internet gateway
resource "aws_internet_gateway" "CustomIGW" {
    vpc_id = "${aws_vpc.CustomVPC.id}"
    tags = {
      Name = "CustomIGW"
    }
  
}

//define the route table
resource "aws_route_table" "CustomRT" {
    vpc_id = "${aws_vpc.CustomVPC.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.CustomIGW.id}"

    }
    tags = {
      Name = "CustomRT"
    }
  
}

//associate the subnet and route table
resource "aws_route_table_association" "RTA" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.CustomRT.id}"
}

//to create security group
resource "aws_security_group" "instanceSG" {
  name = "instanceSG"
  vpc_id = "${aws_vpc.CustomVPC.id}"
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_network_interface" "this-nic" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  security_groups = ["${aws_security_group.instanceSG.id}"]
  tags = {
    Name = "CustomNIC"
  }
}

//create ebs volume
resource "aws_ebs_volume" "rootvol" {
  availability_zone = "ap-south-1a"
  size = 30
  encrypted = false
}

//create instance
resource "aws_instance" "TerraformInstance" {
    ami = "ami-08e7239dc2220a91a"
    instance_type = "t2.micro"
    key_name = "Windowsinstancekey"
    network_interface {
      network_interface_id = "${aws_network_interface.this-nic.id}"
      device_index = 0
    }
    subnet_id = "${aws_subnet.public-subnet.id}"
    vpc_security_group_ids = [ "${aws_security_group.instanceSG.id}" ]
    associate_public_ip_address = true
    tags = {
      Name = "Terraform-Instance"
    }
    
}

//attache ebs volume
resource "aws_volume_attachment" "ebsvolattach" {
    device_name = "/dev/sdc"
    volume_id = "${aws_ebs_volume.rootvol.id}"
    instance_id = "${aws_instance.TerraformInstance.id}"
  
}
