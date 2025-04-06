---------------*-----------------Terraform Configuration for Deploying a Node.js Application---------------*-----------------

   *Overview

   This Terraform configuration automates the deployment of a Node.js application on an AWS EC2 instance. 
   The setup includes:

>>VPC and Subnet creation

>>Security group allowing only SSH (port 22) and application access on TCP port 3000.

>>Elastic IP allocation and association with the EC2 instance.

>>EC2 instance with t2.micro as instance type.

>>Terraform provisioners for copying source code and executing setup scripts.
--------------------------------------------------------------------------------------------------------------------------------------------
   *Prerequisites
   Before running the Terraform script, ensure you have:

>>Terraform Installed: Download and install Terraform from terraform.io.

>>AWS Credentials Configured: Ensure AWS credentials are set up using aws configure or environment variables.

--------------------------------------------------------------------------------------------------------------------------------------------
   *Deployment Instructions

1. Initialize Terraform
   terraform init

2. Plan the Deployment
   terraform plan

3. Apply the Configuration
   terraform apply -auto-approve

4. Retrieve the Public IP
   After successful execution, Terraform will output the assigned public IP address:
   echo "Application is running at: http://$(terraform output -raw ec2_public_ip):3000"
--------------------------------------------------------------------------------------------------------------------------------------------
   *Terraform Resources Created

1. VPC
Creates a custom VPC with a CIDR block of 10.0.0.0/16.

2. Subnet
Creates a public subnet 10.0.1.0/24 in availability zone us-east-1a.
map_public_ip_on_launch is enabled to allow automatic public IP assignment.

3. Security Group
Allows SSH (port 22) and Node.js application (port 3000) from all sources (0.0.0.0/0).
Allows all outbound traffic.

4. Internet Gateway & Route Table
Creates an Internet Gateway and a route table with a default route (0.0.0.0/0).
Associates the route table with the public subnet.

5. Elastic IP & EC2 Instance
Allocates an Elastic IP and associates it with the EC2 instance.
Deploys an EC2 instance (t2.micro) using Ubuntu AMI (ami-084568db4383264d4).
Attaches the security group and subnet.

6. Provisioners
Terraform provisioners are used to automate setup:

a) File Provisioner
Copies the application source code (quest_app) to /home/ubuntu/app inside the EC2 instance.
Copies the installation script (questapp_install.sh) to /home/ubuntu/.

b) Remote Exec Provisioner
Executes commands remotely to install dependencies and start the application:

   questapp_install.sh Script Details
   This script performs the following:

>>Updates package lists (apt update -y)
>>Installs nodejs and npm
>>Sets permissions for the application directory
>>Installs dependencies using npm install
>>Starts the application with nohup npm start on port 3000
--------------------------------------------------------------------------------------------------------------------------------------------
   *Validation & Access

1. SSH into EC2 Instance
ssh -i Quest_Key.pem ubuntu@<EC2_PUBLIC_IP>

2. Check Application Logs
cat /home/ubuntu/deploy.log

3. Verify Application Running
Open a browser and navigate to:
http://<EC2_PUBLIC_IP>:3000/
You should see the application responding.
--------------------------------------------------------------------------------------------------------------------------------------------
   *Cleanup
To destroy all created resources, run:
terraform destroy -auto-approve

This will remove the EC2 instance, Elastic IP, VPC, and all associated resources.

   *Additional Notes

Ensure port 3000 is exposed by the application (server.js or app.js).
Modify the security group rules if additional ports are required.

   *Conclusion

This Terraform configuration automates the infrastructure setup and deployment of a Node.js application on AWS. By using Terraform provisioners, the application is copied, installed, and executed seamlessly upon instance creation.

Author: Nayan Kumar
