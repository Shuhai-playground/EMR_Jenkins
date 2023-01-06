# configure this ec2 instance to talk to the private nodes
# ec2 will be the bastion host

resource "aws_security_group" "ssh_sg" {
  name        = "allow_ssh"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["87.183.174.191/32"]
  }
}

resource "aws_key_pair" "bastion_host" {
  key_name   = "bastion-key-pair"
  public_key = file("~/.ssh/bastion.pub")
}

# resource "aws_key_pair" "key_nodes" {
#   key_name   = "key_nodes"
#   public_key = file("~/.ssh/bastion")
# }


resource "aws_instance" "example" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  subnet_id     = aws_subnet.public_us_east_1a.id

  key_name      = aws_key_pair.bastion_host.key_name

  tags = {
    Name = "instance_talk_to_nodes"
  }
}

# security group for nodes
resource "aws_security_group" "node_sg" {
  name        = "allow_ssh_node"
  description = "Allow SSH access to node"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# resource "aws_security_group" "node_sg" {
#   name        = "bastion-security-group"
#   description = "Security group for the bastion host"

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     security_groups = [aws_security_group.bastion_ingress.id]
#   }
# }

# resource "aws_security_group" "bastion_ingress" {
#   name        = "bastion-ingress-security-group"
#   description = "Security group for the bastion host ingress"

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["<bastion_host_public_ip>/32"]
#   }
# }