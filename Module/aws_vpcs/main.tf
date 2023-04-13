


provider "aws" {
  region  = var.region
  profile = var.profile
  # max_retries = 10
  # http_client {
  #   connection_timeout = "120s"
  #   expect_continue_timeout = "5s"
  #   idle_conn_timeout = "120s"
  #   response_header_timeout = "60s"
  # }
}
provider "aws" {
  alias = "demo"
  region = var.region
  profile = "demo"
  # max_retries = 10
  # http_client {
  #   connection_timeout = "120s"
  #   expect_continue_timeout = "5s"
  #   idle_conn_timeout = "120s"
  #   response_header_timeout = "60s"
  # }
  
}
provider "aws" {
  alias = "dev"
  region = var.region
  profile = "dev"
  # max_retries = 10
  # http_client {
  #   connection_timeout = "120s"
  #   expect_continue_timeout = "5s"
  #   idle_conn_timeout = "120s"
  #   response_header_timeout = "60s"
  # }
  
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


# Load balancer security group
resource "aws_security_group" "load_balancer_sg" {
  name        = "load_balancer_sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Allow two kind of inbound traffic for load balancer"

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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "web_security_group" {
  name = "DechengSg"
  description = "Allow inbound traffic for app instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  ingress {
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
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


# output "public_ip" {
#   value = aws_instance.ec2-instance.public_ip
# } 因为不用单个EC2了，所以用下面的部分，直接获取 ASG 实例的公共 IP 是比较困难的，因为它们是动态创建的。一个更好的方法是使用负载均衡器的 DNS 名称作为输出

output "load_balancer_dns_name" {
  value = aws_lb.app_load_balancer.dns_name
}







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
                "s3:DeleteBucketLifecycle"
            ]
            # Resource= "*"
            
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

data "template_file" "user_data" {

 template = <<EOF
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

 

}

//we delete the single EC2 create resources, using aws_launch_configuration 
//and aws_autoscaling_group to create dynamicly EC2 instance.
# Launch Configuration
resource "aws_launch_template" "asg_launch_template" {
  name_prefix = "asg_launch_template"

  image_id      = data.aws_ami.webserver.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2-keypair.key_name

  #vpc_security_group_ids = [aws_security_group.web_security_group.id]
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_security_group.id]
    delete_on_termination       = true
  }
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  user_data = base64encode(data.template_file.user_data.rendered)
  

   block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 50
      volume_type           = "gp2"
      delete_on_termination = true
       kms_key_id  = aws_kms_key.ebs_key.arn
      encrypted   = true
    }
  }
  

}


# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name_prefix="web_asg" 
  #和下面的launch_template重复
  #launch_configuration = aws_launch_template.asg_launch_template.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  default_cooldown          = 60
  //vpc_zone_identifier  = [aws_subnet.public_subnet[0].id]
  //This option configures the Auto Scaling Group to launch EC2 instances across three subnets. This helps distribute instances across different availability zones, increasing fault tolerance and high availability. If one availability zone experiences an issue, instances in other availability zones can still continue to operate.
  vpc_zone_identifier  = [aws_subnet.public_subnet[0].id,aws_subnet.public_subnet[1].id,aws_subnet.public_subnet[2].id] 

  //update自动缩放组以使用负载均衡器目标组
  target_group_arns    = [aws_lb_target_group.app_target_group.arn]
launch_template {

 id = aws_launch_template.asg_launch_template.id

 version = "$Latest"

 }
 #wait_for_capacity_timeout = "20m" # Increase the timeout to 20 minutes

  tag {
    key                 = "Name"
    value               = "DC-ec2"
    //used to identify which ec2 instance is new one
    propagate_at_launch = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "CPU usage exceeds 10%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "CPU usage is below 5%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}


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
   kms_key_id = aws_kms_key.rds_key.arn
  storage_encrypted = true
  tags = {
    Name = "webApp-rds-instance"
  }
}


resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnets"
  subnet_ids = aws_subnet.private_subnet.*.id //privateç
   lifecycle {
    prevent_destroy = false
  }
}



# Create the Application Load Balancer
resource "aws_lb" "app_load_balancer" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  #ip_address_type    = "dualstack" # Add this line to set IP address type

  subnets = [
    aws_subnet.public_subnet[0].id,
    aws_subnet.public_subnet[1].id,
    aws_subnet.public_subnet[2].id
  ]
  #scheme = "internet-facing" # default you do not need to mention


  tags = {
    Name = "app-load-balancer"
  }
}

# Create a target group for the load balancer to forward traffic to
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  target_type = "instance"
  port     = var.application_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 60
    path                = "/healthz"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher=200
  }
}
#Assignment 9 not allow 80 any more;
# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.app_load_balancer.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_target_group.arn
#   }
# }

# Register the Auto Scaling Group instances as targets
# resource "aws_autoscaling_attachment" "asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.web_asg.id
#   alb_target_group_arn   = aws_lb_target_group.app_target_group.arn
# } 
//这个attachment和
//target_group_arns = [aws_lb_target_group.app_target_group.arn]重复了





data "aws_route53_zone" "demo" {
  provider = aws.demo
  name         = var.demo_domain_name
}


data "aws_acm_certificate" "imported_certificate" {
  provider = aws.demo
  domain   = var.demo_domain_name
  statuses = ["ISSUED"]
}






# 首先，删除现有的 aws_acm_certificate，aws_route53_record 和 aws_acm_certificate_validation 资源，因为它们是用于请求新证书的。
# resource "aws_acm_certificate" "certificate" {
#   provider = aws.demo
  
#   domain_name       = var.demo_domain_name
#   validation_method = "DNS"
#   tags = {
#     Environment = "production"
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "validation" {
#   provider = aws.demo
#   allow_overwrite = true
#   name    = element(aws_acm_certificate.certificate.domain_validation_options[*].resource_record_name, 0)
#   type    = element(aws_acm_certificate.certificate.domain_validation_options[*].resource_record_type, 0)
#   records = [element(aws_acm_certificate.certificate.domain_validation_options[*].resource_record_value, 0)]
#   zone_id = data.aws_route53_zone.demo.zone_id
#   ttl     = 60
# }
# resource "aws_acm_certificate_validation" "valid" {
#   provider = aws.demo
#   certificate_arn         = aws_acm_certificate.certificate.arn
#   validation_record_fqdns = aws_route53_record.validation.*.fqdn
# }





data "aws_route53_zone" "dev" {
  provider = aws.dev
 name         = var.dev_domain_name
 #name         = "dev.dechengxu.me"
}
#这段代码对应着AWS Certificate -> Manager Certificates-> Request certificate
resource "aws_acm_certificate" "certificate_dev" {
  provider = aws.dev
  domain_name       = var.dev_domain_name
  validation_method = "DNS"
  tags = {
    Environment = "develop"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation_dev" {
  provider = aws.dev
  allow_overwrite = true
  name    = element(aws_acm_certificate.certificate_dev.domain_validation_options[*].resource_record_name, 0)
  type    = element(aws_acm_certificate.certificate_dev.domain_validation_options[*].resource_record_type, 0)
  records = [element(aws_acm_certificate.certificate_dev.domain_validation_options[*].resource_record_value, 0)]
  zone_id = data.aws_route53_zone.dev.zone_id
  ttl     = 60
}
resource "aws_acm_certificate_validation" "valid_dev" {
  provider = aws.dev
  certificate_arn         = aws_acm_certificate.certificate_dev.arn
  validation_record_fqdns = aws_route53_record.validation_dev.*.fqdn
}



data "aws_route53_zone" "root" {
  provider = aws.root
  #name         = "dechengxu.me"

  name         = var.root_domain_name
}

resource "aws_acm_certificate" "certificate_root" {
  provider = aws.root
  domain_name       = var.root_domain_name
  validation_method = "DNS"
  tags = {
    Environment = "root"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation_root" {
  provider = aws.root
  allow_overwrite = true
  name    = element(aws_acm_certificate.certificate_root.domain_validation_options[*].resource_record_name, 0)
  type    = element(aws_acm_certificate.certificate_root.domain_validation_options[*].resource_record_type, 0)
  records = [element(aws_acm_certificate.certificate_root.domain_validation_options[*].resource_record_value, 0)]
  zone_id = data.aws_route53_zone.root.zone_id
  ttl     = 60
}
resource "aws_acm_certificate_validation" "valid_root" {
  provider = aws.root
  certificate_arn         = aws_acm_certificate.certificate_root.arn
  validation_record_fqdns = aws_route53_record.validation_root.*.fqdn
}






resource "aws_route53_record" "DC_record_root" {
  provider = aws.root

  name    = var.root_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.root.zone_id

  alias {
    name                   = aws_lb.app_load_balancer.dns_name
    zone_id                = aws_lb.app_load_balancer.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "DC_record_dev" {
  provider = aws.dev

  name    = var.dev_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.dev.zone_id

  alias {
    name                   = aws_lb.app_load_balancer.dns_name
    zone_id                = aws_lb.app_load_balancer.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "DC_record_demo" {
  provider = aws.demo
  name    = var.demo_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.demo.zone_id

  alias {
    name                   = aws_lb.app_load_balancer.dns_name
    zone_id                = aws_lb.app_load_balancer.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
    
  }
}

# choose one of three since only one can be in effect when you tf apply


# resource "aws_lb_listener" "https_listener_dev" {
#   provider = aws.dev
#   load_balancer_arn = aws_lb.app_load_balancer.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate_validation.valid_dev.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_target_group.arn
#   }
# }

# choose one of three since only one can be in effect when you tf apply


resource "aws_lb_listener" "https_listener_demo" {
  provider = aws.demo
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.imported_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# choose one of three since only one can be in effect when you tf apply

# resource "aws_lb_listener" "https_listener_root" {
#   provider = aws.root
#   load_balancer_arn = aws_lb.app_load_balancer.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate_validation.valid_root.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_target_group.arn
#   }
# }

#A9 for dev,using AWS IAM user dev account 814613584038
# resource "aws_kms_key" "ebs_key" {
#   description = "customer-managed KMS key"
#   # Allow the IAM user or role specified in the "principal" block to use the key
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         "Sid": "Enable IAM User Permissions",
#         "Effect": "Allow",
#         "Principal": {
#           "AWS": ["arn:aws:iam::814613584038:user/DechengXu",aws_iam_role.ec2_role.arn]
#         },
#         "Action": "kms:*",
#         "Resource": "*"
#       },
#       {
#         "Sid" : "Enable kms access for auto scaling",
#         "Effect" : "Allow",
#         "Principal" : {
#           "AWS" : "arn:aws:iam::814613584038:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
#         },
#         "Action" : "kms:*",
#         "Resource" : "*",
#       }
#     ]
#   })
# }


#A9 for demo,using AWS IAM user demo account 187570859166
resource "aws_kms_key" "ebs_key" {
  description = "customer-managed KMS key"
  # Allow the IAM user or role specified in the "principal" block to use the key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid": "Enable IAM User Permissions",
        "Effect": "Allow",
        "Principal": {
          "AWS": ["arn:aws:iam::187570859166:user/DechengXu",aws_iam_role.ec2_role.arn]
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Sid" : "Enable kms access for auto scaling",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::187570859166:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        "Action" : "kms:*",
        "Resource" : "*",
      }
    ]
  })
}

resource "aws_kms_key" "rds_key" {
  description = "RDS encryption key"
}




