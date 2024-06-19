FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04

# Install packages without prompting the user to answer any questions
ENV DEBIAN_FRONTEND noninteractive 

RUN export https_proxy=http://10.200.13.85:3128 && http_proxy=http://10.200.13.85:3128

# Install packages
RUN apt update && apt install -y \
build-essential \
libgl1-mesa-dev \
libglew-dev \
libsdl2-dev \
libsdl2-image-dev \
libglm-dev \
libfreetype6-dev \
libglfw3-dev \
libglfw3 \
libglu1-mesa-dev \
freeglut3-dev \
python3-pip \
lsb-release \
git \
neovim \
tmux \
wget \
curl \
htop \
libssl-dev \
build-essential \
dbus \ 
dbus-x11 \
mesa-utils \
libgl1-mesa-glx \
software-properties-common \
tmux \
psmisc \
screen \
python-is-python3 \
x11-apps \
tcl tk expect aria2 net-tools;

RUN pip install numpy==1.24 open3d alphashape ortools

RUN git config --global credential.helper store

# Install ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt update && \
    apt install -y ros-noetic-desktop-full python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential


# Configure ROS
ENV ROS_DISTRO noetic

RUN apt update && apt install -y \
python3-wstool python3-catkin-tools python3-empy \
protobuf-compiler libgoogle-glog-dev \
ros-$ROS_DISTRO-control-toolbox \
ros-$ROS_DISTRO-octomap-msgs \
ros-$ROS_DISTRO-octomap-ros \
ros-$ROS_DISTRO-mavros \
ros-$ROS_DISTRO-mavros-extras \
ros-$ROS_DISTRO-mavros-msgs \
ros-$ROS_DISTRO-rviz-visual-tools \
ros-$ROS_DISTRO-gazebo-plugins \
ros-$ROS_DISTRO-octomap* \
ros-$ROS_DISTRO-dynamic-edt-3d \
ros-$ROS_DISTRO-gazebo* ;

RUN chsh -s /bin/bash

# Custom env_var settings for root
RUN echo "export https_proxy=http://10.200.13.85:3128 && http_proxy=http://10.200.13.85:3128" >> /root/.bashrc
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc

RUN export https_proxy=http://10.200.13.85:3128 && http_proxy=http://10.200.13.85:3128
RUN exec bash && source /opt/ros/noetic/setup.bash
RUN rosdep init
RUN rosdep update

ARG UID=1000
ARG GID=1000

# Update the package list, install sudo, create a non-root user, and grant password-less sudo permissions
RUN apt update && \
    apt install -y sudo && \
    addgroup --gid $GID ros && \
    adduser --uid $UID --gid $GID --disabled-password --gecos "" ros && \
    echo 'ros ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Default non-root user
USER ros

# Set the working directory
WORKDIR /home/ros/dev
RUN mkdir share

# Install pip dependencies:
RUN pip install future

# Custom env_var settings for ros
# If needed, the proxy can be 'unset' 
RUN echo "export https_proxy=http://10.200.13.85:3128 && http_proxy=http://10.200.13.85:3128" >> /home/ros/.bashrc
RUN echo "source /opt/ros/noetic/setup.bash" >> /home/ros/.bashrc
RUN export https_proxy=http://10.200.13.85:3128 && http_proxy=http://10.200.13.85:3128

# Clone Ardupilot Source
RUN git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
WORKDIR /home/ros/dev/ardupilot
# Install dependecies for Ardupilot
# The $USER must be assgined for prereqs
ARG USER=ros
RUN Tools/environment_install/install-prereqs-ubuntu.sh -y
RUN . ~/.profile
# Build with sitl config (can be changed later)
RUN ./waf configure --board sitl
RUN ./waf clean 
RUN ./waf
# Install MAVROS
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    chmod a+x install_geographiclib_datasets.sh && \
    sudo ./install_geographiclib_datasets.sh

# Install Gazebo plugin for ArduPilot Master
WORKDIR /home/ros/dev
RUN git clone https://github.com/khancyr/ardupilot_gazebo.git
WORKDIR /home/ros/dev/ardupilot_gazebo
# Build
RUN mkdir build && \
    cd build && \
    cmake .. && \
    make -j4 && \
    sudo make install
# Set env-var
RUN echo 'source /usr/share/gazebo/setup.sh' >> /home/ros/.bashrc
RUN echo 'export GAZEBO_MODEL_PATH=~/ardupilot_gazebo/models' >> ~/.bashrc
RUN . ~/.bashrc

WORKDIR /home/ros/dev

COPY ./ros_entrypoint.sh /

ENTRYPOINT ["/ros_entrypoint.sh"]

CMD ["bash"]
