FROM  pytorch/pytorch:1.6.0-cuda10.1-cudnn7-devel AS python_img

LABEL maintainer="szoke.laszlo95@edu.bme.hu"
LABEL docker_image_name="Pytorch remote development"
LABEL description="This container is created to use SUMO with Pytorch or TensorFlow and Keras"

# System settings
RUN echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
RUN sysctl -p --system

# Gnome-terminal and locales
ENV LANG=en_US.UTF-8
RUN apt-get update -qq && apt-get install -qy gnome-terminal libcanberra-gtk-module libcanberra-gtk3-module locales
RUN echo 'LANG=en_US.UTF-8' > '/etc/default/locale' && \
    locale-gen --lang en_US.UTF-8 && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG
# Install make and compilers and extra stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -qy \
    build-essential autoconf automake \
    sudo vim nano git curl wget tmux \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libxext6 \
    libx11-6 \
    gcc git openssh-client libfontconfig1 \
    emacs python tcpdump telnet byacc flex \
    iproute2 gdbserver less bison valgrind \
    libxtst-dev libxext-dev libxrender-dev libfreetype6-dev \
    openssh-server cmake gdb build-essential clang llvm lldb && \
    apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*
    
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# install PyCharm
WORKDIR /opt
RUN curl -fsSL -o pycharm-professional.tar.gz "https://data.services.jetbrains.com/products/download?code=PCP&platform=linux" && \
    tar xzf pycharm-professional.tar.gz && \
    rm pycharm-professional.tar.gz && \
    mv pycharm* pycharm

RUN python /opt/pycharm/plugins/python/helpers/pydev/setup_cython.py build_ext --inplace

# Add executables
RUN echo "/opt/pycharm/bin/pycharm.sh &" > /usr/bin/pycharm && chmod +x /usr/bin/pycharm

RUN echo "PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment

RUN conda update -n base -c defaults conda
RUN conda install tensorflow-gpu==2.1.0
RUN conda install tensorflow-estimator==2.1.0
RUN conda install -c conda-forge gym easygui matplotlib opencv control 

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
ENTRYPOINT /entry.sh

FROM python_img AS sumo_img
LABEL maintainer="szoke.laszlo95@edu.bme.hu"
LABEL docker_image_name="SUMO environment with Pytorch"
LABEL description="This container is created to use SUMO with Pytorch or TensorFlow and Keras"

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
RUN echo "PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/sumo/tools:/usr/share/sumo" >> /etc/environment

FROM python_img AS carla_img

LABEL maintainer="szoke.laszlo95@edu.bme.hu"
LABEL docker_image_name="Carla with Python/Pytorch/Tensorflow"
LABEL description="This container is created for Carla with Pytorch or TensorFlow and Keras"

WORKDIR /opt/carla
RUN chmod -R 777 .
COPY --from=carlasim/carla:0.9.10 /home/carla/ .

RUN conda install pandas
RUN conda install -c conda-forge opencv


