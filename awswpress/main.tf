variable "awsprops" {
  type = map(string)
  default = {
    region = "eu-west-2"
    vpc = "vpc-0abaf64456b8500d8"
    ami = "ami-0fb391cce7a602d1f"
    itype = "t2.micro"
    subnet = "subnet-0c201de70a6200b62"
    publicip = true
    keyname = "wpress"
    secgroupname = "wpress"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_security_group" "project-iac-sg" {
  name = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Pinging
  ingress {
    from_port = 8
    protocol = "icmp"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "project-iac" {
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = lookup(var.awsprops, "subnet")
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name = lookup(var.awsprops, "keyname")


  vpc_security_group_ids = [
    aws_security_group.project-iac-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    # iops = 150
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="wpress"
    Environment = "learning"
    OS = "Amazon Linux"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.project-iac-sg ]

  user_data = "${file("wpress.sh")}"

}

output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}
