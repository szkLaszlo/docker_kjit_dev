#XAUTH file for remote GUI
export XAUTH=/tmp/.carla_docker.xauth
echo $XAUTH
DISPLAY=$DISPLAY
sudo rm -rf $XAUTH
touch $XAUTH

xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | sudo xauth -f $XAUTH nmerge -
sudo chmod 777 $XAUTH
