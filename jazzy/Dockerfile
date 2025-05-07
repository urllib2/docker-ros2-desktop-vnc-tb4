# Base image with Ubuntu Noble
FROM ubuntu:noble-20250404

# Platform arguments
ARG TARGETPLATFORM
ARG TARGETARCH
ARG QEMU_CPU

LABEL maintainer="Tiryoh<tiryoh@gmail.com>"

SHELL ["/bin/bash", "-c"]

# Regional Ubuntu mirror and timezone setup
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://tn.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apt-get update \
 && apt-get install -y tzdata \
 && rm -rf /var/lib/apt/lists/*

# Install base tools and dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      lsb-release \
      wget \
      gnupg \
      curl \
      netbase \
      git \
      python3-pip \
      emacs htop byobu less \
      mesa-utils vulkan-tools \
      libnvidia-gl-535 nvidia-utils-535 \
      terminator \
      dbus-x11 \
      libcanberra-gtk-module \
      libcanberra-gtk3-module \
 && rm -rf /var/lib/apt/lists/*

# Install Ubuntu MATE desktop and VNC components
RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ubuntu-mate-desktop && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        tigervnc-standalone-server tigervnc-common \
        supervisor wget curl gosu git sudo python3-full python3-pip tini \
        build-essential vim sudo lsb-release locales \
        bash-completion tzdata terminator && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Install noVNC and websockify
RUN git clone https://github.com/AtsushiSaito/noVNC.git -b add_clipboard_support /usr/lib/novnc
RUN pip install --no-cache-dir --break-system-packages git+https://github.com/novnc/websockify.git@v0.10.0
RUN ln -s /usr/lib/novnc/vnc.html /usr/lib/novnc/index.html
RUN sed -i "s/UI.initSetting('resize', 'off');/UI.initSetting('resize', 'remote');/g" /usr/lib/novnc/app/ui.js

# Disable auto-update and crash reports
RUN sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
RUN sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

# Install Firefox
RUN wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg \
    -O /etc/apt/keyrings/packages.mozilla.org.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
    | tee -a /etc/apt/sources.list.d/mozilla-apt.list && \
    echo "Package: *" | tee /etc/apt/preferences.d/mozilla > /dev/null && \
    echo "Pin: origin packages.mozilla.org" | tee -a /etc/apt/preferences.d/mozilla > /dev/null && \
    echo "Pin-Priority: 1000" | tee -a /etc/apt/preferences.d/mozilla > /dev/null && \
    apt-get update -q && \
    apt-get remove -y firefox && \
    apt-get install -y \
    firefox && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Install VSCodium
RUN wget https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    -O /usr/share/keyrings/vscodium-archive-keyring.asc && \
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.asc ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' \
    | tee /etc/apt/sources.list.d/vscodium.list && \
    apt-get update -q && \
    apt-get install -y codium && \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Install ROS Jazzy
ENV ROS_DISTRO jazzy
ARG INSTALL_PACKAGE=desktop

RUN apt-get update -q && \
    apt-get install -y curl gnupg2 lsb-release && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update -q && \
    apt-get install -y ros-${ROS_DISTRO}-${INSTALL_PACKAGE} \
    python3-argcomplete \
    python3-colcon-common-extensions \
    python3-rosdep python3-vcstool && \
    rosdep init && \
    rm -rf /var/lib/apt/lists/*

RUN rosdep update

# Install ROS simulation packages
RUN apt-get update -q && \
    apt-get install -y \
    ros-${ROS_DISTRO}-ros-gz && \
    rm -rf /var/lib/apt/lists/*

# Install Gazebo Harmonic
ARG GZ_VERSION=harmonic
RUN wget https://packages.osrfoundation.org/gazebo.gpg \
     -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
     http://packages.osrfoundation.org/gazebo/ubuntu-stable \
     $(lsb_release -cs) main" \
     | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
 && apt-get update \
 && apt-get install -y --no-install-recommends "gz-${GZ_VERSION}" \
 && rm -rf /var/lib/apt/lists/*

# Additional ROS packages for TurtleBot4
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ros-${ROS_DISTRO}-teleop-twist-keyboard \
      && \
    rm -rf /var/lib/apt/lists/*

# Set up overlay workspace for TurtleBot4 simulation
ARG OVERLAY_WS=/opt/ros/overlay_ws
WORKDIR $OVERLAY_WS/src

# Clone repositories
RUN GIT_TERMINAL_PROMPT=0 \
    git clone https://github.com/ros-controls/gz_ros2_control.git -b ${ROS_DISTRO} || \
    ( echo "WARN: Branch '${ROS_DISTRO}' not found for gz_ros2_control; cloning default." && \
      GIT_TERMINAL_PROMPT=0 git clone https://github.com/ros-controls/gz_ros2_control.git )

RUN GIT_TERMINAL_PROMPT=0 \
    git clone https://github.com/turtlebot/turtlebot4_simulator.git -b ${ROS_DISTRO} || \
    ( echo "WARN: Branch '${ROS_DISTRO}' not found for turtlebot4_simulator; cloning default." && \
      GIT_TERMINAL_PROMPT=0 git clone https://github.com/turtlebot/turtlebot4_simulator.git )

# Install dependencies and build overlay
WORKDIR $OVERLAY_WS
RUN . /opt/ros/$ROS_DISTRO/setup.sh \
 && apt-get update \
 && rosdep install -y --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} \
 && rm -rf /var/lib/apt/lists/*

RUN . /opt/ros/$ROS_DISTRO/setup.sh \
 && colcon build --symlink-install

# Source overlay workspace in .bashrc
ENV OVERLAY_WS=$OVERLAY_WS
RUN echo "source \$OVERLAY_WS/install/setup.bash" >> /root/.bashrc

# Terminator configuration
ENV NO_AT_BRIDGE=1
RUN mkdir -p /etc/xdg/terminator && \
    touch /etc/xdg/terminator/config && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      at-spi2-core \
      python3-gi \
      gir1.2-keybinder-3.0 \
      gir1.2-notify-0.7 \
      libnotify-bin && \
    rm -rf /var/lib/apt/lists/*

RUN echo '[global_config]\n\
  suppress_multiple_term_dialog = True\n\
[keybindings]\n\
[profiles]\n\
  [[default]]\n\
    use_system_font = False\n\
    font = Monospace 10\n\
[layouts]\n\
  [[default]]\n\
    [[[window0]]]\n\
      type = Window\n\
      parent = ""\n\
    [[[child1]]]\n\
      type = Terminal\n\
      parent = window0\n\
[plugins]' > /etc/xdg/terminator/config

# NVIDIA and GUI settings
ENV DISPLAY=:0 \
    QT_X11_NO_MITSHM=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute

# Copy and configure entrypoint
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Enable apt-get completion
RUN rm /etc/apt/apt.conf.d/docker-clean

ENTRYPOINT [ "/bin/bash", "-c", "/entrypoint.sh" ]

ENV USER ubuntu
ENV PASSWD ubuntu

CMD ["/bin/bash"]