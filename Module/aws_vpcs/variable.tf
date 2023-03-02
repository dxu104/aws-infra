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

variable "public_key_path" {
   default= "~/.ssh/ec2.pub"
  description = "local path of key pair"
  type = string
}

variable "db-password" {
   default= "root1234"
  description = "password of db"
  type = string
}
variable "db-name" {
   default= "csye6225"
  description = "name of db"
  type = string
}

variable "db-username" {
   default= "root"
  description = "username of db"
  type = string
}

variable "AWS_ACCESS_KEY_ID" {
   default= "AKIASXLAYFSPGTHERZUJ"
  description = "id"
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
   default= "h2UT4l41LyxA9O4igX9ZQKNC04w5CTLAmon5MYLC"
  description = "key"
  type = string
}

variable "hostname" {
   default= "csye6225_DC"
  description = "name"
  type = string
}







