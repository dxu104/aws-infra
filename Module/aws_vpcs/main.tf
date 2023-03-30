

provider "aws" {
  region  = var.region
  profile = var.profile
}
provider "aws" {
  alias = "dev"
  region = var.region
  profile = "dev"
  
}
provider "aws" {
  alias = "root"
  region = var.region
  profile = "root"
  
}

# Create VPC
# terraform aws create vpc
resource "aws_vpc" "vpc" {
  
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "igw" {
 
  vpc_id = aws_vpc.vpc.id
}

# Create  3 public subnet 

resource "aws_subnet" "public_subnet" {
  count = var.public_subnets_num
  cidr_block        = cidrsubnet(var.vpc-cidr,8,count.index+10)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "subnet-public-${count.index + 1}"
  }
}

# Create the Public Route Table
resource "aws_route_table" "public_rt" {
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  vpc_id = aws_vpc.vpc.id

  tags = {

    Name = "route-public-tbl"
  }




}

# Associate the Public Route Table with Public Subnets
resource "aws_route_table_association" "public_subnet_rta" {
  count        = var.public_subnets_num

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

















# Create  3 private subnet 
resource "aws_subnet" "private_subnet" {
  count      = var.private_subnets_num
  cidr_block = cidrsubnet(var.vpc-cidr,8,count.index+1)
  vpc_id     = aws_vpc.vpc.id
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "subnet-private-${count.index + 1}"
  }
}


# Create private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {

    Name = "route-private-table"


  }
}


resource "aws_route_table_association" "private_subnet_rta" {

  count          = var.private_subnets_num
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}





resource "aws_security_group" "web_security_group" {
  name = "DechengSg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



#create EC2 instance based on your lastest AMI in your AWS account 
data "aws_ami" "webserver" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CSYE6225webapp*"]
  }
}

resource "aws_key_pair" "ec2-keypair" {
  key_name   = "sameAsEc2"
  public_key = file(var.public_key_path)

  lifecycle {
    prevent_destroy = false
  }
  
  #I have a ec2 and ec2.pub in my cd ~/.ssh  
  #In your case, the key_name attribute is 
  #set to "ec2", which means that 
  #you should have a key pair in your AWS account with the name "ec2".
}


output "public_ip" {
  value = aws_instance.ec2-instance.public_ip
}


# resource "aws_db_subnet_group" "rds_instance_subnet_group" {
#   name       = "rds_instance_subnet_group"
#   subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
# }



  # Add more parameters as desired


//action 这里不能写*，权限太大了，要改
// arn:aws：s3 ：：：这里写bucket name这里要从环境变量里面拿
//第二个arn:aws：s3 ：：代表policy用于所有的object in the bucket

resource "aws_iam_policy" "web_app_s3_policy" {
  name = "WebAppS3"
  policy = jsonencode({
    Version= "2012-10-17"
    Statement=[
        {
          Effect= "Allow"
            Action = [
                "s3:Get*",
                "s3:List*",
                "s3:PutObject",
                "s3:DeleteObject*",
                
            ]
            
            Resource= [
                "arn:aws:s3:::${aws_s3_bucket.csye6225_DC_bucket.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.csye6225_DC_bucket.bucket}/*",
               
            ]
        }
    ]
})

lifecycle {
    prevent_destroy = false
  }
}

# "route53:List*",
#                 "route53:Get*",
#                 "route53:ChangeResourceRecordSets",
# "arn:aws:route53:::hostedzone/${data.aws_route53_zone.AWS_hosted_zone.zone_id}",
               # "arn:aws:route53:::change/*"


resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  policy_arn = aws_iam_policy.web_app_s3_policy.arn
  role = aws_iam_role.ec2_role.name
}
data "aws_iam_policy" "cloudwatch_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  policy_arn = data.aws_iam_policy.cloudwatch_policy.arn
  role       = aws_iam_role.ec2_role.name
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-CSYE6225-profile"
  role = aws_iam_role.ec2_role.name
}
resource "aws_instance" "ec2-instance" {
  ami = data.aws_ami.webserver.id # Use the AMI ID retrieved by the data block
  #ami = var.ami_id # Replace with your custom AMI ID
  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2-keypair.key_name
  associate_public_ip_address = true
  
  subnet_id = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.web_security_group.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  root_block_device {
    volume_size = 50
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags = {
    Name = "DC-ec2"
  }
  user_data = <<-EOF
      #!/bin/bash
      
      sudo chown -R ec2-user /etc/bashrc
      sudo chgrp -R ec2-user /etc/bashrc
      # Set environment variables for the application
      
      echo "export DB_HOST=${aws_db_instance.rds_instance.endpoint}">> /etc/bashrc
      echo "export DB_NAME=${var.db-name}">> /etc/bashrc
      echo "export DB_USERNAME=${var.db-username}">> /etc/bashrc
      echo "export DB_PASSWORD=${var.db-password}">> /etc/bashrc
      echo "export BUCKET_NAME=${aws_s3_bucket.csye6225_DC_bucket.bucket}">> /etc/bashrc
      echo "export AMIId=${data.aws_ami.webserver.id}">> /etc/bashrc
      echo "export REGION=${var.region}">> /etc/bashrc
      
      sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/cloudWatchAgentConfig.json
      
      
      sudo chown -R ec2-user /var/log/myapp/
      sudo chgrp -R ec2-user /var/log/myapp/


      source /etc/bashrc  
      sudo systemctl restart JavaService
      
      
        
    EOF
 lifecycle {
    prevent_destroy = false
  }
  

}
# 更改属主 sudo chown -R ec2-user /etc/bashrc
 # 更改属组     sudo chgrp -R ec2-user /etc/bashrc
#sudo chmod -v 755 /etc/bashrc
# mkdir -p /var/log/myapp
#       sudo chmod -v 777 /var/log/myapp
#chown -R ec2-user:ec2-user /var/log/myapp

#sudo systemctl restart JavaService
 #cd /opt/ && java -jar HomeWork1-0.0.1-SNAPSHOT.jar
//echo "export AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID}">> /etc/bashrc
//echo "export AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_ACCESS_KEY}">> /etc/bashrc


//add the following for introduce RDS
//for assignment 6, you need to create a new database securtiy group
//
resource "aws_security_group" "rds_security-group" {
  name_prefix = "rds_security-group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [aws_security_group.web_security_group.id]
    #cidr_blocks = [aws_subnet.public_subnet[0].cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "random_uuid" "main" {}

resource "aws_kms_key" "mykey" {
  description = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 15
}

resource "aws_s3_bucket" "csye6225_DC_bucket" {
  bucket = "s3bucket-${random_uuid.main.result}"

  tags = {
    Name = "s3bucket-${random_uuid.main.result}"
    # Environment ="Dev"
  }

  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket_sse" {
  bucket = aws_s3_bucket.csye6225_DC_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      #kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "private_bucket_acl" {
  bucket = aws_s3_bucket.csye6225_DC_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_rule" {
  bucket = aws_s3_bucket.csye6225_DC_bucket.id

  rule {
    id      = "log"
    status  = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
 

resource "aws_db_parameter_group" "rds-paragrp" {
  name_prefix = "rds-paragrp"
  family      = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}
resource "aws_db_instance" "rds_instance" {
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  multi_az             = false
  skip_final_snapshot = true
 
  identifier           = "csye6225"
  username             = var.db-username
  password             = var.db-password
  publicly_accessible  = false
  db_name              = var.db-name
  vpc_security_group_ids = [aws_security_group.rds_security-group.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  parameter_group_name = aws_db_parameter_group.rds-paragrp.id
  allocated_storage    = 20
}


resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnets"
  subnet_ids = aws_subnet.private_subnet.*.id //privateç
   lifecycle {
    prevent_destroy = false
  }
}

# data "aws_route53_zone" "AWS_hosted_zone" {
#   name = var.domain_name
# }
  //associate_public_ip_address = true I need to do this in aws_instance resource for To make this work, you need to ensure that the aws_instance resource is assigned a public IP address. This can be done by specifying associate_public_ip_address = true within the aws_instance resource.

resource "aws_route53_record" "DC_record_root" {
  provider = aws.root

  name    = var.root_domain_name
  type    = "A"
  ttl     = "60"
  records = [aws_instance.ec2-instance.public_ip]
  zone_id = var.root_zone_id
  lifecycle {
    create_before_destroy=true
  }
}
resource "aws_route53_record" "DC_record_dev" {
  provider = aws.dev
  name    = var.dev_domain_name
  type    = "A"
  ttl     = "60"
  records = [aws_instance.ec2-instance.public_ip]
  zone_id = var.dev_zone_id
  lifecycle {
    create_before_destroy=true
  }
}

resource "aws_route53_record" "DC_record_demo" {
  
  name    = var.domain_name
  type    = "A"
  ttl     = "60"
  records = [aws_instance.ec2-instance.public_ip]
  zone_id = var.demo_zone_id
  lifecycle {
    create_before_destroy=true
  }
}


