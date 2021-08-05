resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4uB3sALsO1c8bDOJVPxShgWHwy1LLJZi8Ssf1GwJVaV32p0V6RhJNqyoc7MOBvhoF6Ef5E5kRqecyqVpqQplKzENCtYT43/nFsd6a7WFw0dr1CBMWw/WtzadPqHBxwa+abGRIQlIgVPHUSQlieQ0SLDtwlwbAYaRVllzjb3fle2BcGk5d+oZObJPlD5Q9i+/M+EDTOiIYhT3QqeBmYhCmZgjmZMHgw8cZ7+9L1FXAs0/vPyuO1WEPGThVco+SaUg8QV9WVucT+BPfsMd/RwFQQLHW4Px0WGdmErcd+9tbmciq49+/uIai4PIYg3T/Jfx6aqIASiciUhz+FzV4SJyn selakoui@FRM02713.local"
}

resource "tls_private_key" "tf" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "SEL - Key"
  public_key = tls_private_key.tf.public_key_openssh
}