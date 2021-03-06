
# CREATING CONFIGURATION FILES

data "template_file" "install_master" {
  template = "${format("%s%s%s%s%s%s%s", file("data/install_common.sh"), file("data/install_master.sh"), file("data/install_metric.sh"), file("data/install_dashboard.sh"), file("data/install_istio.sh"), file("data/install_ha.sh"), file("data/install_registry.sh") )}"

  vars = {
    ip_node_1 = "${aws_instance.node_1.private_ip}"
    ip_node_2 = "${aws_instance.node_2.private_ip}"
    ip_node_3 = "${aws_instance.node_3.private_ip}"
    extra_key = "${var.extra_key}"
    efs_dns = "${aws_efs_file_system.efs_prod.dns_name}"
  }
}

data "template_file" "install_node" {
  template = "${format("%s%s", file("data/install_common.sh"), file("data/install_node.sh"))}"

  vars = {
    extra_key = "${var.extra_key}"
    efs_dns = "${aws_efs_file_system.efs_prod.dns_name}"
  }
}

# MASTER

resource "aws_ebs_volume" "master_ebs" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp3"

  tags = {
    Name = "Master"
  }
}

resource "aws_volume_attachment" "master_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.master_ebs.id
  instance_id = aws_instance.master.id
}


resource "aws_instance" "master" {
  ami             = var.ami
  instance_type   = "t2.large"
  key_name        = aws_key_pair.generated_key.key_name
  subnet_id       = aws_subnet.sel_public.id
  security_groups = [aws_security_group.sel_ssh.id]

  #user_data = "${data.template_file.install_master.rendered}"

  provisioner "remote-exec" {
    inline = [
      "${data.template_file.install_master.rendered}",
    ]
  }

  connection {
    type        = "ssh"
    user        = "admin"
    password    = ""
    private_key = "${tls_private_key.tf.private_key_pem}"
    host        = self.public_ip
  }

   root_block_device {
    volume_size           = "20"
    volume_type           = "gp2"
    delete_on_termination = true

    tags = {
      "Name" = "SEL - Web PreProd"
    }
  }

  tags = {
    "Name" = "SEL - Master"
  }
}

# NODE 1

resource "aws_ebs_volume" "node_1_ebs" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp3"

  tags = {
    Name = "Node 1"
  }
}

resource "aws_volume_attachment" "node_1_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.node_1_ebs.id
  instance_id = aws_instance.node_1.id
}

resource "aws_instance" "node_1" {
  ami             = var.ami
  instance_type   = "t2.large"
  key_name        = aws_key_pair.generated_key.key_name
  subnet_id       = aws_subnet.sel_public.id
  security_groups = [aws_security_group.sel_ssh.id]

  #user_data = "${data.template_file.install_node.rendered}"

  provisioner "remote-exec" {
    inline = [
      "${data.template_file.install_node.rendered}",
    ]
  }

  connection {
    type        = "ssh"
    user        = "admin"
    password    = ""
    private_key = "${tls_private_key.tf.private_key_pem}"
    host        = self.public_ip
  }

  root_block_device {
    volume_size           = "20"
    volume_type           = "gp2"
    delete_on_termination = true

    tags = {
      "Name" = "SEL - Web PreProd"
    }
  }

  tags = {
    "Name" = "SEL - Node 1"
  }
}

# NODE 2
resource "aws_ebs_volume" "node_2_ebs" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp3"

  tags = {
    Name = "Node 1"
  }
}

resource "aws_volume_attachment" "node_2_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.node_2_ebs.id
  instance_id = aws_instance.node_2.id
}

resource "aws_instance" "node_2" {
  ami             = var.ami
  instance_type   = "t2.large"
  key_name        = aws_key_pair.generated_key.key_name
  subnet_id       = aws_subnet.sel_public.id
  security_groups = [aws_security_group.sel_ssh.id]

  #user_data = "${data.template_file.install_node.rendered}"
  
  provisioner "remote-exec" {
    inline = [
      "${data.template_file.install_node.rendered}",
    ]
  }

  connection {
    type        = "ssh"
    user        = "admin"
    password    = ""
    private_key = "${tls_private_key.tf.private_key_pem}"
    host        = self.public_ip
  }

  root_block_device {
    volume_size           = "20"
    volume_type           = "gp2"
    delete_on_termination = true

    tags = {
      "Name" = "SEL - Web PreProd"
    }
  }
   
  tags = {
    "Name" = "SEL - Node 2"
  }
} 

#NODE 3
resource "aws_ebs_volume" "node_3_ebs" {
  availability_zone = "${var.region}a"
  size              = 100
  type              = "gp3"

  tags = {
    Name = "Node 1"
  }
}

resource "aws_volume_attachment" "node_3_ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.node_3_ebs.id
  instance_id = aws_instance.node_3.id
}

resource "aws_instance" "node_3" {
  ami             = "ami-04e905a52ec8010b2"
  instance_type   = "t2.large"
  key_name        = aws_key_pair.generated_key.key_name
  subnet_id       = aws_subnet.sel_public.id
  security_groups = [aws_security_group.sel_ssh.id]

  #user_data = "${data.template_file.install_node.rendered}"

  provisioner "remote-exec" {
    inline = [
      "${data.template_file.install_node.rendered}",
    ]
  }

  connection {
    type        = "ssh"
    user        = "admin"
    password    = ""
    private_key = "${tls_private_key.tf.private_key_pem}"
    host        = self.public_ip
  }

  root_block_device {
    volume_size           = "20"
    volume_type           = "gp2"
    delete_on_termination = true

    tags = {
      "Name" = "SEL - Web PreProd"
    }
  }

  tags = {
    "Name" = "SEL - Node 3"
  }
}
