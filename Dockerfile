FROM ubuntu:20.04

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"

LABEL maintainer="szoke.laszlo95@edu.bme.hu"
LABEL docker_image_name="SUMO environment with Pytorch"
LABEL description="This container is created to use SUMO with Pytorch or TensorFlow and Keras"

# Install make and compilers and extra stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install --no-install-recommends -qy \
    openssh-client openssh-server \
    python3.8 \
    python3-pip \
    sudo \
    wget && \
    apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh 
    
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
	
ENV SUMO_HOME /usr/share/sumo

RUN conda install pytorch torchvision cudatoolkit=10.2 -c pytorch
RUN pip3 install gym easygui

WORKDIR /workspace
RUN chmod -R 777 /workspace

RUN echo "PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/sumo/tools/" >> /etc/environment

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
ENTRYPOINT /entry.sh
