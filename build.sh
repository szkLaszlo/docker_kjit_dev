# This is an example of building the docker with the target image sumo for bme use.
docker build --build-arg LOC=bme --build-arg MID_IMAGE=sumo -t sumo-dev --target final_image --no-cache .