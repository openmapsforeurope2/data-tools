PROJECT_NAME=data-tools
DOCKER_NAME=$PROJECT_NAME

GIT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
GIT_BRANCH_LOWER=$(echo $GIT_BRANCH | tr '[:upper:]' '[:lower:]')

DOCKER_TAG=$(head -n 1 ./../VERSION)

if [ $GIT_BRANCH = "main" ]
then
    DOCKER_TAG="latest"
fi

echo $GIT_BRANCH
echo $DOCKER_TAG

docker build \
    --label org.opencontainers.image.source=https://github.com/openmapsforeurope2/$PROJECT_NAME \
    --no-cache \
    -t $DOCKER_NAME:$DOCKER_TAG \
    -f Dockerfile ./..
