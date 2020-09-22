FROM pytorch/pytorch:1.6.0-cuda10.1-cudnn7-devel

LABEL maintainer="szoke.laszlo95@edu.bme.hu"
LABEL docker_image_name="SUMO environment with Pytorch"
LABEL description="This container is created to use SUMO with Pytorch or TensorFlow and Keras"

# Install make and compilers and extra stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get install --no-install-recommends -qy \
    openssh-client openssh-server \
    sudo \
    vim \
    wget && \
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
	sumo-doc
	
ENV SUMO_HOME /usr/share/sumo

RUN echo "PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/sumo/tools/" >> /etc/environment

RUN conda install pytorch torchvision cudatoolkit=10.1 -c pytorch

RUN conda install -c anaconda tensorflow-gpu

RUN conda install -c conda-forge gym easygui matplotlib

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
ENTRYPOINT /entry.sh
