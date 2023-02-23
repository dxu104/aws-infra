variable "vpc-cidr" {
  default = "10.0.0.0/16"
  description = "vpc cidr block"
  type = string
}
variable "availability_zones" {
  default= ["us-west-2a", "us-west-2b", "us-west-2c"]
  description = "vpc cidr block"
  type = list
}

variable "vpc-tag" {
  default= ["us-west-2a", "us-west-2b", "us-west-2c"]
  description = "vpc cidr block"
  type = list
}


variable "vpc_name" {
   default= "my_vpc"
  description = "vpc name"
  type = string
}

variable "public_subnets_num" {
   default= 3
  description = "public subnets num"
  type = number
}

variable "private_subnets_num" {
  default= 3
  description = "private subnets num"
  type = number
}

variable "profile" {
  type = string
  description = "profile"
}

variable "region" {
   default= "us-west-2"
  description = "region name"
  type = string
}
variable "ami_id" {
   default= "ami-04e61c2967631a8e3"
  description = "ami_id"
  type = string
}

