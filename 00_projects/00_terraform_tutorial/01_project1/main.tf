
# This example was base on below video:
# https://www.youtube.com/watch?v=SLB_c_ayRMo&t=6625s
# 
provider "aws" {
  region = "us-east-1"
  # use your own serect key and access key
  access_key = "Access key"
  secret_key = "secret key"
}
# 1. create VPC
resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "tf_vpc"
  }
}
# 2 create internet gateway
resource "aws_internet_gateway" "tf_ig" {
    vpc_id = aws_vpc.tf_vpc.id
    tags = {
        Name = "tf_internet_gateway"
    }
} 
# 3 create route table
resource "aws_route_table" "tf_rt" {
    vpc_id = aws_vpc.tf_vpc.id
    route = [ {
      cidr_block = "0.0.0.0/0"
      egress_only_gateway_id = ""
      gateway_id = aws_internet_gateway.tf_ig.id
      instance_id = ""
      ipv6_cidr_block = ""
      local_gateway_id = ""
      nat_gateway_id = ""
      network_interface_id = ""
      transit_gateway_id = ""
      vpc_endpoint_id = ""
      vpc_peering_connection_id = ""
    } ]
    tags = {
        Name = "tf_route_table"
    }
}
# 4 create a subnet
resource "aws_subnet" "tf_subnet_1" {
    vpc_id = aws_vpc.tf_vpc.id
    cidr_block = "10.0.1.0/24"
    tags = {
        Name = "tf_subnet_1"
    }
    availability_zone = "us-east-1a"
}
# 5 associate subnet to route table
resource "aws_route_table_association" "tf_subnet_to_rt" {
    subnet_id = aws_subnet.tf_subnet_1.id
    route_table_id = aws_route_table.tf_rt.id
}
# 6 create a security group
resource "aws_security_group" "tf_sg" {
    name = "alow_web_traffic"
    description = "allow web traffic"
    vpc_id      = aws_vpc.tf_vpc.id
    ingress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "TCP traffic"
      from_port = 443
      ipv6_cidr_blocks = [ "::/0" ]
      prefix_list_ids = [  ]
      protocol = "TCP"
      security_groups = [  ]
      self = true
      to_port = 443
    } ,
    { cidr_blocks = [ "0.0.0.0/0" ]
      description = "ssh"
      from_port = 80
      ipv6_cidr_blocks = [ "::/0" ]
      prefix_list_ids = [  ]
      protocol = "TCP"
      security_groups = [  ]
      self = true
      to_port = 80
    },
    { cidr_blocks = [ "0.0.0.0/0" ]
      description = "ssh"
      from_port = 22
      ipv6_cidr_blocks = [ "::/0" ]
      prefix_list_ids = [  ]
      protocol = "TCP"
      security_groups = [  ]
      self = true
      to_port = 22
    }]
    egress = [ {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "out"
      from_port = 0
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      protocol = "-1"
      security_groups = [  ]
      self = true
      to_port = 0
    } ]
    tags = {
        Name = "tf_sg"
    }
}
# 7 create network interface
resource "aws_network_interface" "tf_ENI" {
    subnet_id = aws_subnet.tf_subnet_1.id
    private_ips = [ "10.0.1.50" ]
    security_groups = [ aws_security_group.tf_sg.id ]
}
# 8 create EIP 
resource "aws_eip" "tf_eip" {
    vpc = true
    network_interface = aws_network_interface.tf_ENI.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [ aws_internet_gateway.tf_ig ]
}
# 9 create EC2 instance
resource "aws_instance" "tf_instance" {
    ami = "ami-0885b1f6bd170450c"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    # please use your own key pair. 
    # my key pair name is new.pem
    key_name = "new"
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.tf_ENI.id
    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server' > /var/www/html/index.html
            EOF
	tags = {
		Name = "tf_instance"	
	}
}
# resource "aws_instance" "test_terraform" {

#     ami = "ami-09bee01cc997a78a6"
#     instance_type = "t2.micro"
#     key_name = "new"
#     tags = {
#       Name = "ubuntu"
#     }
#     security_groups = ["Amazon ECS-Optimized Amazon Linux 2 AMI-2-0-20201028-AutogenByAWSMP-1"]
#     provisioner "remote-exec"{
#         inline = ["docker run -d -p 8000:8000 phancuong91/websortingvisualization",]
#         connection {
#             host = aws_instance.test_terraform.public_ip
#             type        = "ssh"
#             private_key = "${file("new.pem")}"
#             user        = "ec2-user"
#             timeout     = "1m"
#         }
#     }
# }