#!/bin/bash
source /home/ec2-user/.bash_profile
cd /home/ec2-user/app/release

# Create logs directory if needed
mkdir -p /home/ec2-user/logs

# Use correct metadata URL
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
export INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export STACK_NAME=$(aws --region $REGION ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=aws:cloudformation:stack-name" | grep -oP '(?<="Value": ")[^"]*')

echo "Running npm start with STACK_NAME=$STACK_NAME"
npm run start