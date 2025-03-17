#!/bin/bash -xe
LOG_FILE="/home/ec2-user/app/release/start-service.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "Sourcing bash profile"
source /home/ec2-user/.bash_profile

echo "Changing directory to /home/ec2-user/app/release"
cd /home/ec2-user/app/release

echo "Querying the EC2 metadata service for this instance's region"
REGION="`wget -qO- http://instance-data/latest/meta-data/placement/availability-zone | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
echo "Region: $REGION"

echo "Querying the EC2 metadata service for this instance's instance-id"
export INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"
echo "Instance ID: $INSTANCE_ID"

echo "Querying EC2 describeTags method to pull out the CFN Logical ID for this instance"
export STACK_NAME=`aws --region $REGION ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=aws:cloudformation:stack-name" | jq -r ".Tags[0].Value"`
echo "Stack Name: $STACK_NAME"

echo "Starting the application"
npm run start