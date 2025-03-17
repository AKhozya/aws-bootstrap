#!/bin/bash
set +e  # Don't exit on errors

# Source bash profile to ensure npm is in path
source /home/ec2-user/.bash_profile

cd /home/ec2-user/app/release || exit 0

echo "Attempting to stop application..."

# Check if package.json exists
if [ -f "package.json" ]; then
    # Use npm stop to properly stop the application
    echo "Running npm stop..."
    npm stop
    echo "npm stop completed"
else
    echo "No package.json found, skipping stop command"
fi

# Always exit successfully
echo "Stop script completed successfully"
exit 0