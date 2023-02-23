

module "vpc" {


  source              = "./Module/aws_vpcs"
  profile             = var.profile
  public_subnets_num  = var.private_subnets_num
  private_subnets_num = var.private_subnets_num
  vpc_name            = "us-west-2-vpc-1"
  vpc-cidr            = var.vpc-cidr
  ami_id              = var.ami_id
  region              = var.region
  availability_zones  = ["${var.region}a", "${var.region}b", "${var.region}c"]


}


# module "vpc1" {


#   source = "./Module/aws_vpcs"
#   profile             = var.profile
#   public_subnets_num=var.private_subnets_num
#   private_subnets_num = var.private_subnets_num
#   vpc_name = "us-west-2-vpc-2"
#   vpc-cidr = "10.1.0.0/16"
#   ami_id = var.ami_id
#   region = var.region

#   availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]

# }

# module "vpc2" {


#   source = "./Module/aws_vpcs"
#   profile             = var.profile
#   public_subnets_num=var.private_subnets_num
#   private_subnets_num = var.private_subnets_num
#   vpc_name = "us-east-2-vpc-1"
#   vpc-cidr = "10.0.0.0/16"
#   region = "us-east-2"
#   availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

# }

# module "vpc3" {


#   source = "./Module/aws_vpcs"
#   profile             = var.profile
#   public_subnets_num=var.private_subnets_num
#   private_subnets_num = var.private_subnets_num
#   vpc_name = "us-east-2-vpc-2"
#   vpc-cidr = "10.1.0.0/16"
#   region = "us-east-2"
#   availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

# }














 