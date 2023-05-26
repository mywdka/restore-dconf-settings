#!/bin/bash

# Add path to background image
FILENAME=dconf-settings.ini
FIND=$(grep 'picture-uri' $FILENAME)
REPLACE=picture-uri-dark="'"file://${PWD}/bg.jpg"'"

for BG in $FIND
do
    sed -i "s@$BG@$REPLACE@" $FILENAME
done

# Add or update systemd service for dconf
RUNAS=$(who am i | awk '{print $1}')
CURRENT_DIR=$(pwd)
SERVICE_NAME="restore-dconf-settings"
DESCRIPTION="Restore dconf settings on boot"
IS_ACTIVE=$(systemctl --user -M ${RUNAS}@ is-active $SERVICE_NAME)

if [ "$IS_ACTIVE" == "active" ]; then
    echo "Service is running"
    echo "Restarting service ..."
    # update logic?
    systemctl restart --user -m ${RUNAS}@ $SERVICE_NAME
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
    systemctl --user -M ${RUNAS}@ enable ${SERVICE_NAME//'.service'/}
    systemctl --user -M ${RUNAS}@ start ${SERVICE_NAME//'.service'/}
    echo "Service started"
fi