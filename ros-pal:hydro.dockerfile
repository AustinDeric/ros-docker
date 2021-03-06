FROM ubuntu:12.04
MAINTAINER Jesse Clark <docker@jessejohnclark.com>

# Register ROS repository
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 5523BAEEB01FA116 && \
echo "deb http://packages.ros.org/ros/ubuntu precise main" > /etc/apt/sources.list.d/ros-latest.list && \
echo "deb-src http://packages.ros.org/ros/ubuntu precise main" >> /etc/apt/sources.list.d/ros-latest.list

ENV ROS_DISTRO hydro

# Install ROS build tools
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    nano \
    python-catkin-tools \
    python-pip \
    python-rosinstall \
    sudo

# Install ROS
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-${ROS_DISTRO}-ros-base
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-${ROS_DISTRO}-common-tutorials \
    ros-${ROS_DISTRO}-rospy-tutorials \
    ros-${ROS_DISTRO}-rosbridge-server
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-${ROS_DISTRO}-desktop-full

# Install PAL dependencies
# note that rosdep should find these automatically, but we are being explicit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-${ROS_DISTRO}-moveit-ros-move-group \
    ros-${ROS_DISTRO}-diff-drive-controller \
    ros-${ROS_DISTRO}-joy \
    ros-${ROS_DISTRO}-ecto-ros \
    ros-${ROS_DISTRO}-control-toolbox \
    ros-${ROS_DISTRO}-moveit-planners-ompl \
    ros-${ROS_DISTRO}-moveit-simple-grasps \
    ros-${ROS_DISTRO}-humanoid-nav-msgs \
    ros-${ROS_DISTRO}-joint-limits-interface \
    ros-${ROS_DISTRO}-object-recognition-ros \
    ros-${ROS_DISTRO}-moveit-fake-controller-manager \
    ros-${ROS_DISTRO}-joint-trajectory-controller \
    ros-${ROS_DISTRO}-moveit-simple-controller-manager \
    ros-${ROS_DISTRO}-ecto \
    ros-${ROS_DISTRO}-moveit-ros-visualization \
    ros-${ROS_DISTRO}-moveit-commander \
    python-scipy \
    ros-${ROS_DISTRO}-controller-manager \
    ros-${ROS_DISTRO}-joint-state-controller \
    ros-${ROS_DISTRO}-play-motion \
    ros-${ROS_DISTRO}-object-recognition-tabletop \
    ros-${ROS_DISTRO}-gazebo-ros-control

# Setup ROS environment globally
RUN echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> /etc/bash.bashrc

# Create nonprivileged user
RUN useradd --create-home --shell=/bin/bash rosuser && \
echo 'rosuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rosuser && \
chmod 440 /etc/sudoers.d/rosuser && \
mkdir -p /etc/ros/rosdep/sources.list.d && \
chgrp -R rosuser /etc/ros && \
chmod -R g+w /etc/ros

# Run rosdep
USER rosuser
RUN . "/opt/ros/${ROS_DISTRO}/setup.sh" && \
rosdep init && \
rosdep update

# Build REEM workspace
RUN . "/opt/ros/${ROS_DISTRO}/setup.sh" && \
mkdir -p ~/reem-sim_ws/src && \
cd ~/reem-sim_ws/src && \
catkin_init_workspace && \
wstool init . && \
wstool merge https://raw.githubusercontent.com/pal-robotics/pal-ros-pkg/master/reem-sim-hydro.rosinstall && \
wstool update -j8
RUN . "/opt/ros/${ROS_DISTRO}/setup.sh" && \
cd ~/reem-sim_ws && \
rosdep install --from-paths src --ignore-src --rosdistro hydro -y && \
catkin_make && \
echo 'source ~/reem-sim_ws/devel/setup.bash' >> ~/.bashrc

# TODO:
# - comment out imu_sensor_controller in src/reem_robot/reem_controller_configuration/launch/default_controllers.launch

ENV EDITOR nano -wi

# Publish roscore and rosbridge port
EXPOSE 11311
EXPOSE 9090
