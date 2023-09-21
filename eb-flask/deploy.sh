NOW=`date +%s`

BRANCH=$1
SHA1=`echo -n $NOW | openssl dgst -sha1 |awk '{print $NF}'`

[[ -z "$BRANCH" ]] && { echo "must pass a branch param" ; exit 1; }

# Main variables to modify for your account
AWS_ACCOUNT_ID=597849092155
NAME='monitoring-app'
AWS_DEFAULT_REGION='ap-southeast-1'

VERSION='latest'

# Authenticate against our Docker registry
#TOKEN=$(aws ecr get-authorization-token --output text --query 'authorizationData[].authorizationToken')
#TOKEN=$(aws ecr get-login-password --region region | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$NAME)
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
export REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
# Build and push the image
echo Build started on `date`
echo Building the Docker image...
docker build -t $NAME:$VERSION .

echo Pushing the Docker image to ECR...
docker tag $NAME:$VERSION $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$NAME:$VERSION
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$NAME:$VERSION
echo Build completed on `date`
echo Deploying new task definition $NAME:$VERSION to ECS cluster...
echo ECS_CLUSTER_NAME - $NAME, ECS_SERVICE_NAME - $NAME
aws ecs update-service --cluster $NAME --service $NAME --force-new-deployment
#aws ecs update-service --cluster $NAME --service $NAME --task-definition $ECS_TASK_DEFINITION --force-new-deployment
echo ECS service $NAME updated


#aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 597849092155.dkr.ecr.ap-southeast-1.amazonaws.com
#docker build -t monitoring-app-demo .
#docker push 597849092155.dkr.ecr.ap-southeast-1.amazonaws.com/monitoring-app-demo:latest