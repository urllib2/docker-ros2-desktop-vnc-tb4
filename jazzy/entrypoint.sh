#!/bin/bash

# Create User
USER=${USER:-root}
HOME=/root
if [ "$USER" != "root" ]; then
    echo "* enable custom user: $USER"
    useradd --create-home --shell /bin/bash --user-group --groups adm,sudo "$USER"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    if [ -z "$PASSWORD" ]; then
        echo "  set default password to \"ubuntu\""
        PASSWORD=ubuntu
    fi
    HOME="/home/$USER"
    echo "$USER:$PASSWORD" | /usr/sbin/chpasswd 2> /dev/null || echo ""
    cp -r /root/{.config,.gtkrc-2.0,.asoundrc} "$HOME" 2>/dev/null
    chown -R "$USER:$USER" "$HOME"
    [ -d "/dev/snd" ] && chgrp -R adm /dev/snd
fi

# VNC password
VNC_PASSWORD=${PASSWORD:-ubuntu}

mkdir -p "$HOME/.vnc"
echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
chown -R "$USER:$USER" "$HOME"
sed -i "s/password = WebUtil.getConfigVar('password');/password = '$VNC_PASSWORD'/" /usr/lib/novnc/app/ui.js

# xstartup
XSTARTUP_PATH="$HOME/.vnc/xstartup"
cat << EOF > "$XSTARTUP_PATH"
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
mate-session
EOF
chown "$USER:$USER" "$XSTARTUP_PATH"
chmod 755 "$XSTARTUP_PATH"

# vncserver launch
VNCRUN_PATH="$HOME/.vnc/vnc_run.sh"
cat << EOF > "$VNCRUN_PATH"
#!/bin/sh

# Workaround for issue when image is created with "docker commit".
# Thanks to @SaadRana17
# https://github.com/Tiryoh/docker-ros2-desktop-vnc/issues/131#issuecomment-2184156856

if [ -e /tmp/.X1-lock ]; then
    rm -f /tmp/.X1-lock
fi
if [ -e /tmp/.X11-unix/X1 ]; then
    rm -f /tmp/.X11-unix/X1
fi

if [ $(uname -m) = "aarch64" ]; then
    LD_PRELOAD=/lib/aarch64-linux-gnu/libgcc_s.so.1 vncserver :1 -fg -geometry 1920x1080 -depth 24
else
    vncserver :1 -fg -geometry 1920x1080 -depth 24
fi
EOF

# Supervisor
CONF_PATH=/etc/supervisor/conf.d/supervisord.conf
cat << EOF > $CONF_PATH
[supervisord]
nodaemon=true
user=root
[program:vnc]
command=gosu '$USER' bash '$VNCRUN_PATH'
[program:novnc]
command=gosu '$USER' bash -c "websockify --web=/usr/lib/novnc 80 localhost:5901"
EOF

# colcon
BASHRC_PATH="$HOME/.bashrc"
grep -F "source /opt/ros/$ROS_DISTRO/setup.bash" "$BASHRC_PATH" || echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> "$BASHRC_PATH"
grep -F "export ROS_AUTOMATIC_DISCOVERY_RANGE=" "$BASHRC_PATH" || echo "# export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST" >> "$BASHRC_PATH"
chown "$USER:$USER" "$BASHRC_PATH"

# Fix rosdep permission
mkdir -p "$HOME/.ros"
cp -r /root/.ros/rosdep "$HOME/.ros/rosdep"
chown -R "$USER:$USER" "$HOME/.ros"

# Add terminator shortcut
mkdir -p "$HOME/Desktop"
cat << EOF > "$HOME/Desktop/terminator.desktop"
[Desktop Entry]
Name=Terminator
Comment=Multiple terminals in one window
TryExec=terminator
Exec=terminator
Icon=terminator
Type=Application
Categories=GNOME;GTK;Utility;TerminalEmulator;System;
StartupNotify=true
X-Ubuntu-Gettext-Domain=terminator
X-Ayatana-Desktop-Shortcuts=NewWindow;
Keywords=terminal;shell;prompt;command;commandline;
[NewWindow Shortcut Group]
Name=Open a New Window
Exec=terminator
TargetEnvironment=Unity
EOF

chown -R "$USER:$USER" "$HOME/Desktop"

echo "============================================================================================"
echo "Launched docker container."
echo -e 'Open \e]8;;http://127.0.0.1:6080\e\\http://127.0.0.1:6080\e]8;;\e\\ via web browser.'
echo ""
echo "NOTE 1: Default user is \"$USER\", password is \"$PASSWORD\"."
echo "NOTE 2: --security-opt seccomp=unconfined flag is required to launch Ubuntu Jammy/Noble based image on some environment."
echo -e 'See \e]8;;https://github.com/Tiryoh/docker-ros2-desktop-vnc/pull/56\e\\https://github.com/Tiryoh/docker-ros2-desktop-vnc/pull/56\e]8;;\e\\'
echo "============================================================================================"

# clearup
PASSWORD=
VNC_PASSWORD=

exec /bin/tini -- supervisord -n -c /etc/supervisor/supervisord.conf
