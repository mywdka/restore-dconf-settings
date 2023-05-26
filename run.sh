#!/bin/bash
while getopts u: flag
do
    case "${flag}" in
        u) USERNAME=${OPTARG};;
    esac
done
if [ -z "$USERNAME" ] 
then 
    USERNAME=$(who am i | awk '{print $1}')
fi

CURRENT_DIR=$(pwd)
SERVICE_NAME="restore-dconf-settings"
DESCRIPTION="Restore dconf settings on boot"
IS_ACTIVE=$(systemctl --user -M ${USERNAME}@ is-active $SERVICE_NAME)

FILENAME=dconf-settings.ini
FIND=$(grep 'picture-uri' $FILENAME)
REPLACE=picture-uri-dark="'"file://${PWD}/bg.jpg"'"

# Add path to background image
for BG in $FIND
do
    sed -i "s@$BG@$REPLACE@" $FILENAME
done

# Add or update systemd service for dconf
if [ "$IS_ACTIVE" == "active" ]; then
    echo "Service is running"
    echo "Restarting service ..."
    # update logic?
    systemctl restart --user -m ${USERNAME}@ $SERVICE_NAME
    echo "Service restarted"
else
    # create service
    echo "Creating service file"
    cat > /etc/systemd/user/${SERVICE_NAME//'"'/}.service << EOF
[Unit]
Description=$DESCRIPTION
After=display-manager.service

[Service]
ExecStart=/bin/bash -c 'dconf load / < ${CURRENT_DIR}/dconf-settings.ini'
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/\$USER/.Xauthority"
Environment="USER=\$USER"

[Install]
WantedBy=default.target
EOF
    # restart daemon, enable and start service
    echo "Reloading daemon and enabling service ..."
    systemctl daemon-reload
    systemctl --user -M ${USERNAME}@ enable ${SERVICE_NAME//'.service'/}
    systemctl --user -M ${USERNAME}@ start ${SERVICE_NAME//'.service'/}
    echo "Service started"
fi