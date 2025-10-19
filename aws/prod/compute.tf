locals {
  control_plane_private_ip = "10.0.0.10"
  worker_nodes = {
    worker-0 = {
      subnet_index = 0
      private_ip   = "10.0.48.10"
    }
    worker-1 = {
      subnet_index = 0
      private_ip   = "10.0.48.11"
    }
    worker-2 = {
      subnet_index = 1
      private_ip   = "10.0.64.10"
    }
    worker-3 = {
      subnet_index = 2
      private_ip   = "10.0.80.10"
    }
  }
  infra_private_ip = "10.0.80.20"
}

resource "aws_instance" "ticketly_auth" {
  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public.id]
  key_name                    = aws_key_pair.ticketly.key_name

  tags = {
    Name        = "ticketly-auth"
    Role        = "auth"
    Environment = terraform.workspace
  }
}

resource "aws_instance" "control_plane" {
  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public[0].id
  private_ip                  = local.control_plane_private_ip
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public.id]
  key_name                    = aws_key_pair.ticketly.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name

  tags = {
    Name        = "ticketly-control-plane"
    Role        = "control-plane"
    Environment = terraform.workspace
  }
}

resource "aws_instance" "worker" {
  for_each = local.worker_nodes

  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.private[each.value.subnet_index].id
  private_ip                  = each.value.private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.worker.id]
  key_name                    = aws_key_pair.ticketly.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  tags = {
    Name        = "ticketly-${each.key}"
    Role        = "worker"
    Environment = terraform.workspace
  }
}

resource "aws_instance" "infra" {
  ami                         = "ami-02d26659fd82cf299"
  instance_type               = "c7i-flex.large"
  subnet_id                   = aws_subnet.private[2].id
  private_ip                  = local.infra_private_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.infra.id]
  key_name                    = aws_key_pair.ticketly.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  tags = {
    Name        = "ticketly-infra"
    Role        = "infra"
    Environment = terraform.workspace
  }
}

resource "aws_key_pair" "ticketly" {
  key_name   = "ticketly-key"
  public_key = file("${path.module}/ticketly-key.pub")
}
