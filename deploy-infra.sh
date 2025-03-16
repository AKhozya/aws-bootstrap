#source aws_credentials.sh

STACK_NAME=awsbootstrap
REGION=eu-west-2
CLI_PROFILE=awsbootstrap
EC2_INSTANCE_TYPE=t2.micro 
DOMAIN=lol-kek-cheburek1111.com

GH_ACCESS_TOKEN=$(cat ~/.github/aws-bootstrap-access-token)
GH_OWNER=$(cat ~/.github/aws-bootstrap-owner)
GH_REPO=$(cat ~/.github/aws-bootstrap-repo)
GH_BRANCH=master

AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap --query "Account" --output text`
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"
echo $CODEPIPELINE_BUCKET

CFN_BUCKET="$STACK_NAME-cfn-$AWS_ACCOUNT_ID"
echo $CFN_BUCKET

# Function to create an S3 bucket if it does not exist
create_bucket_if_not_exists() {
  BUCKET_NAME=$1
  if ! aws s3api head-bucket --bucket $BUCKET_NAME --region $REGION --profile $CLI_PROFILE 2>/dev/null; then
    echo "\n\n=========== Creating S3 bucket: $BUCKET_NAME ==========="
    aws s3 mb s3://$BUCKET_NAME --region $REGION --profile $CLI_PROFILE
  fi
}

# Create the S3 buckets if they do not exist
create_bucket_if_not_exists $CODEPIPELINE_BUCKET
create_bucket_if_not_exists $CFN_BUCKET

# Deploys static resources
echo "\n\n=========== Deploying setup.yml ==========="
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME-setup \
  --template-file setup.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    CodePipelineBucket=$CODEPIPELINE_BUCKET \
    CloudFormationBucket=$CFN_BUCKET

# Package up CloudFormation templates into an S3 bucket
echo "\n\n=========== Packaging main.yml ===========" 
mkdir -p ./cfn_output

PACKAGE_ERR="$(aws cloudformation package \
  --region $REGION \
  --profile $CLI_PROFILE \
  --template main.yml \
  --s3-bucket $CFN_BUCKET \
  --output-template-file ./cfn_output/main.yml 2>&1)"

if ! [[ $PACKAGE_ERR =~ "Successfully packaged artifacts" ]]; then
  echo "ERROR while running 'aws cloudformation package' command:" 
  echo $PACKAGE_ERR
  exit 1
fi

# Deploy the CloudFormation template
echo "\n\n=========== Deploying main.yml ===========" 
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME \
  --template-file ./cfn_output/main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EC2InstanceType=$EC2_INSTANCE_TYPE \
    Domain=$DOMAIN \
    GitHubOwner=$GH_OWNER \
    GitHubRepo=$GH_REPO \
    GitHubBranch=$GH_BRANCH \
    GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
    CodePipelineBucket=$CODEPIPELINE_BUCKET

# If the deploy succeeded, show the DNS name of the endpoints
if [ $? -eq 0 ]; then
  aws cloudformation list-exports \
    --profile awsbootstrap \
    --query "Exports[?ends_with(Name,'LBEndpoint')].Value"
fi