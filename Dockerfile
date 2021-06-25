# Options: company, bme
ARG LOC

ARG BASE_IMG=pytorch/pytorch:1.6.0-cuda10.1-cudnn7-devel
# Defining the building bases for the different versions
ARG CARLA_BASE=python
ARG ROS_BASE=carla
# Adding the final layers e.g. extra packages
ARG TEMP_IMAGE=sumo

# in case of carla, use these
ARG CARLA_VERSION=0.9.11
ARG MAP_FILE=https://carla-releases.s3.eu-west-3.amazonaws.com/Linux/AdditionalMaps_$CARLA_VERSION.tar.gz

FROM ${BASE_IMG} AS company_version
ENV http_proxy=http://172.17.0.1:3128
ENV https_proxy=http://172.17.0.1:3128
ENV NO_PROXY=*.bosch.com,127.0.0.1

RUN echo 'Acquire::http::proxy "http://172.17.0.1:3128/";'  >> /etc/apt/apt.conf.d/05proxy && \
    echo 'Acquire::https::proxy "http://172.17.0.1:3128/";'  >> /etc/apt/apt.conf.d/05proxy && \
    echo 'Acquire::ftp::proxy "http://172.17.0.1:3128/";' >> /etc/apt/apt.conf.d/05proxy

FROM ${BASE_IMG} AS bme_version
RUN echo "No proxy setup necessary."

FROM ${LOC}_version AS python_img

LABEL maintainer="szoke.laszlo@kjk.bme.hu"
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
    gcc x11-apps git openssh-client libfontconfig1 \
    emacs python tcpdump telnet byacc flex \
    iproute2 gdbserver less bison valgrind \
    libxtst-dev libxext-dev libxrender-dev libfreetype6-dev \
    openssh-server cmake gdb build-essential clang llvm lldb && \
    apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*
    
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt install -qqy krb5-user krb5-locales libpam-krb5

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

RUN echo "PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment
RUN echo "PYTHONPATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /etc/environment

RUN conda update -n base -c defaults conda
RUN conda install pandas
RUN conda install tensorflow-gpu==2.1.0
RUN conda install tensorflow-estimator==2.1.0

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
ENTRYPOINT /entry.sh

FROM python_img AS sumo_img
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
RUN echo "PYTHONPATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/sumo/tools:/usr/share/sumo" >> /etc/environment
RUN pip install gym easygui matplotlib opencv-python control

FROM mwendler/wget as temp_carla
ENV http_proxy=http://172.17.0.1:3128
ENV https_proxy=http://172.17.0.1:3128
ARG MAP_FILE
RUN wget -S --no-check-certificate $MAP_FILE

FROM carlasim/carla:$CARLA_VERSION  as carla_server
ARG CARLA_VERSION
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute
ENV http_proxy=http://172.17.0.1:3128
ENV https_proxy=http://172.17.0.1:3128
USER root
RUN apt-get update && apt-get install -y xdg-user-dirs xdg-utils python3-pip && apt-get clean
RUN pip3 install gdown
USER carla
WORKDIR /home/carla
COPY --from=temp_carla /AdditionalMaps_$CARLA_VERSION.tar.gz Import/
COPY carla-package-NGSIM-openDD.tar.gz Import/

RUN ./ImportAssets.sh

FROM ${CARLA_BASE}_img as carla_img
ARG CARLA_VERSION

COPY --from=carla_server /home/carla/PythonAPI/carla/dist/carla-$CARLA_VERSION-py3.7-linux-x86_64.egg /carla_packages/
RUN echo "PYTHONPATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/sumo/tools:/usr/share/sumo:/carla_packages/carla-$CARLA_VERSION-py3.7-linux-x86_64.egg" >> /etc/environment

RUN pip install pygame

##### ROSSSSS
FROM ${ROS_BASE}_img as ros_img

RUN DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y \
    python3-ros* python-message-filters python-rospy python-rosbag python-rosnode python-geometry-msgs \
    python-catkin-pkg python-sensor-msgs python-visualization-msgs && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN cp -r /usr/lib/python2.7/dist-packages/visualization_msgs/ /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/sensor_msgs/ /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/std_msgs/ /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/geometry_msgs /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/genpy /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/message_filters /opt/conda/lib/python3.7/site-packages/  && \
    cp -r /usr/lib/python2.7/dist-packages/genmsg /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/ros* /opt/conda/lib/python3.7/site-packages/ && \
    cp -r /usr/lib/python2.7/dist-packages/catkin /opt/conda/lib/python3.7/site-packages/ && \
    rm -rf /opt/conda/lib/python3.7/site-packages/message_filters/__init__.py

COPY ros/ros_message_filter/__init__.py /opt/conda/lib/python3.7/site-packages/message_filters/

RUN pip install pydot catkin_pkg rospkg utm

WORKDIR /workspace
ENV PYTHONPATH=$PYTHONPATH:/workspace:/opt/ros/kinetic/lib/python2.7/dist-packages

FROM ${TEMP_IMAGE}_img as final_image

RUN pip install gym[atari]
RUN pip install pytorch-lightning-bolts
RUN pip install pytorch-lightning-bolts["extra"]
RUN pip install gym==0.12.5 pygame==1.9.6 scikit-image==0.16.2
RUN pip install lxml
