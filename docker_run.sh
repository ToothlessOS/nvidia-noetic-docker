CONTAINER_NAME="noetic_docker"
IMAGE_NAME="hf/nvidia-ros-noetic"
SHARED_DIR="/home/toothlessos/projects/mas/docker_nvidia_noetic/shared_dir"
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]
then
    xauth_list=$(xauth nlist :0 | sed -e 's/^..../ffff/')
    if [ ! -z "$xauth_list" ]
    then
        echo $xauth_list | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi

xhost +

docker run -it \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="$XSOCK:$XSOCK:rw" \
    --env="DISPLAY=$DISPLAY" \
    --volume="$HOME/.Xauthority:/root/.Xauthority:ro" \
    --env="XAUTHORITY=$XAUTH" \
    --volume="$XAUTH:$XAUTH" \
    --net=host \
    --gpus all \
    --volume="$SHARED_DIR:$SHARED_DIR" \
    --name=$CONTAINER_NAME \
    $IMAGE_NAME \
    bash

