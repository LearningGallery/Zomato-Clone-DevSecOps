resource "aws_instance" "ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name
  associate_public_ip_address = true
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.0499
    }
  }
  
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
  
  /* ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  } */

  iam_instance_profile = var.iam_instance_profile

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  #user_data = file("${path.module}/../../scripts/bootstrap_script_for_ubuntu.sh")

  provisioner "file" {
    source      = "${path.module}/../../scripts/bootstrap_script_for_ubuntu.sh"
    destination = "/home/ubuntu/bootstrap_script_for_ubuntu.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/bootstrap_script_for_ubuntu.sh",
      "sudo /home/ubuntu/bootstrap_script_for_ubuntu.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  tags = {
    Name = "${var.project_name}-instance"
  }
}