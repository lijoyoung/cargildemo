variable "pvt_subnet_1_cidr" {
  default     = "10.0.2.0/24"
  description = "Your AZ-1"
}

variable "pvt_subnet_2_cidr" {
  default     = "10.0.3.0/24"
  description = "Your AZ-2"
}

variable "az_1" {
  default     = "ap-southeast-1a"
  description = "Your Az1, use AWS CLI to find your account specific"
}

variable "az_2" {
  default     = "ap-southeast-1b"
  description = "Your Az2, use AWS CLI to find your account specific"
}

