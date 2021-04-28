#! /bin/bash
export XAUTH=/tmp/.carla_docker.xauth
echo "Starting the client container..../s The server can be reached with IP 172.17.0.1"
docker-compose -f ./docker-compose.yml run carla_client
