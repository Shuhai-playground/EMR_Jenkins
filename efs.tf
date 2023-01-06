resource "aws_security_group" "jenkins" {
  name = "jenkins"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    protocol = "tcp"
    from_port = 0
    to_port = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  
}

# attach the security group to eks

# resource "aws_launch_template" "attach_security_group" {
#   name = "attach_sg"
#   image_id = "ami-0bd2678b647d05ee3"
#   instance_type = "t3.medium"
#   vpc_security_group_ids = [ aws_security_group.jenkins.id ]

  
# }


resource "aws_efs_file_system" "jenkins_storage" {
  creation_token = "jenkins"
  performance_mode = "generalPurpose"
}

resource "aws_efs_mount_target" "jenkins_storage" {
  file_system_id = aws_efs_file_system.jenkins_storage.id
  subnet_id      = aws_subnet.private_us_east_1a.id
  security_groups = [aws_security_group.jenkins.id]
  
}

resource "aws_efs_mount_target" "jenkins_storage_2" {
  file_system_id = aws_efs_file_system.jenkins_storage.id
  subnet_id      = aws_subnet.private_us_east_1b.id
  security_groups = [aws_security_group.jenkins.id]
  
}

output "efs" {
  value = aws_efs_file_system.jenkins_storage.id
  
}


