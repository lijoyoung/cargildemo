variable "private_key_path" {
  description = <<DESCRIPTION
Path to the SSH private key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/lijoKeySingapore.pem
DESCRIPTION
# default     = "~/.ssh/lijoKeySingapore.pem"
}

variable "key_name" {
  description = "Enter an existing AWS key-pair name in your region, that will be used to launch an instance. Eg: lijoKeySingapore"
  # default     = "lijoKeySingapore"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "ap-southeast-1"
}

# Ubuntu Precise 12.04 LTS (x64)
variable "aws_amis" {
  default = {
    eu-west-1 = "ami-03ef731cc103c9f09"
    us-east-1 = "ami-04763b3055de4860b"
    us-west-1 = "ami-0dbf5ea29a7fc7e05"
    us-west-2 = "ami-0994c095691a46fb5"
    ap-southeast-1 = "ami-0ee0b284267ea6cde"
    ap-south-1 = "ami-0927ed83617754711"
  }
}

# Db related variables
variable "identifier" {
  default     = "mydb-rds"
  description = "Identifier for your DB"
}

variable "storage" {
  default     = "10"
  description = "Storage size in GB"
}

variable "engine" {
  default     = "mysql"
  description = "Engine type, example values mysql, postgres"
}

variable "engine_version" {
  description = "Engine version"

  default = {
    mysql    = "5.7.21"
    postgres = "9.6.8"
  }
}

variable "instance_class" {
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "db_name" {
  default     = "mydb"
  description = "db name"
}

variable "username" {
  default     = "myuser"
  description = "User name"
}

variable "password" {
  default     = "welcome1"
  description = "password, provide through your ENV variables"
}
