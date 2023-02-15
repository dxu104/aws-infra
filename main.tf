

module "vpc" {
 

  source = "./Module/aws_vpcs"
  profile             = var.profile
  public_subnets_num=var.private_subnets_num
  private_subnets_num = var.private_subnets_num
  vpc_name = "my_vpc"
  #cidr_block = "10.0.0.0/16"
  region = var.region
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]


}

# module "us-west-2-vpc1" {
#   region              = "us-west-2"
#   profile             = var.profile
#   source              = "./Modules"
#   vpc-cidr            = "10.0.0.0/16"
#   vpc-tag             = "us-west-2-vpc1"
#   public_subnets_num  = 3
#   private_subnets_num = 3
#   availability_zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]
# }


 
 
 
 
 
 
 