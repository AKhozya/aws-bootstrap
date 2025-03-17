#!/bin/bash
source /home/ec2-user/.bash_profile
cd /home/ec2-user/app/release
npm stop || true

# Always succeed regardless of what happened above
exit 0