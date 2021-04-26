#! /bin/bash
echo "Update the Xauth file, for forwarding the GUI through tunnel..."
./update_xauth.sh
echo "Starting the client container..../s The server can be reached with IP 172.17.0.1"
docker-compose -f ./docker-compose.carla.yml run carla_client
