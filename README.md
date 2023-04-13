
   # CSYE 6225 Project

   ### Please following below steps to run this application

   1. Firstly, change current directory to "aws-infra" folder


   2. execute the following command    
   ```"aws configure list-profiles" to check all profile names
   "aws configure --profile <profile-name>" to change your profile you want
         
   terraform init
      terraform validate
      terraform plan
      terraform apply 
      terraform apply -var-file="demo.tfvars" -var-file="ami_id.tfvars" --auto-approve
      terraform destroy -var-file="dev.tfvars" --auto-approve
      -var-file="demo.tfvars" is let profile = var.profile in AWS provider source, which is dev
      and dev can refer to ~/.asw.configure file 

      yes
   ```

   3. login into your IAM root user, choose Oregen region, go to VPC tab.
   4. Command to Import SSL Certificate:
   ```
   aws --profile demo acm import-certificate --certificate fileb://demo_dechengxu_me.crt --certificate-chain fileb://demo_dechengxu_me.ca-bundle --private-key fileb://private.txt
   ```

