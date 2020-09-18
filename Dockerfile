FROM ubuntu:20.04

LABEL maintainer="szoke.laszlo95@edu.bme.hu"
LABEL docker_image_name="SUMO environment with Pytorch"
LABEL description="This container is created to use SUMO with Pytorch or TensorFlow and Keras"

# Gnome-terminal and locales
ENV LANG=en_US.UTF-8

# Install make and compilers and extra stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install --no-install-recommends -qy \
    python3.8 \
    python3-pip && \
    apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN apt-get update && \
	apt-get install -y software-properties-common && \
	rm -rf /var/lib/apt/lists/*

# Installing SUMO
RUN add-apt-repository ppa:sumo/stable 
RUN apt-get update && apt-get install -y --no-install-recommends \
	sumo \
	sumo-tools \
	sumo-doc \
	vim # Installing vim

RUN pip3 install torch torchvision

WORKDIR /workspace
RUN chmod -R 777 /workspace

RUN echo "PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
ENTRYPOINT /entry.sh
