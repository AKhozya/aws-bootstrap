#!/bin/bash
# Debug: Add timestamps and logging
exec > >(tee -a /home/ec2-user/stop-service-$(date +%Y%m%d-%H%M%S).log)
exec 2>&1
echo "$(date): Starting stop-service.sh"

source /home/ec2-user/.bash_profile
echo "$(date): Sourced bash profile"

cd /home/ec2-user/app/release
echo "$(date): Changed directory to app/release"

echo "$(date): Listing running processes before stop"
ps aux | grep node
pm2 list

echo "$(date): Attempting npm stop"
timeout 60 npm stop
STOP_RESULT=$?
echo "$(date): npm stop completed with status: $STOP_RESULT"

# Kill any stuck processes if npm stop failed or timed out
if [ $STOP_RESULT -ne 0 ]; then
  echo "$(date): npm stop failed or timed out, killing processes forcefully"
  
  # Find and kill node processes belonging to this app
  pkill -f "node.*hello_aws" || true
  
  # Kill any PM2 daemon processes if needed
  pkill -f "PM2" || true
fi

echo "$(date): Verifying all processes are stopped"
ps aux | grep node

echo "$(date): Stop service completed"
exit 0  # Always exit successfully