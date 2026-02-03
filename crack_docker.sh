#!/bin/sh

# The script assumes Plex Media Server is currently running, that you have a mounted `/config` volume in the container, and that your container is named `plex`.
# If your container is named differently or if your external volume is mounted elsewhere, change it at the top of the script instead of running it piped from curl.

PLEX_CONFIG_DIR=/config
PLEX_CONTAINER_NAME=plex
PLEX_MEDIA_SERVER_DIR=$(ps aux | grep 'Plex Media Server' | grep -v grep | awk '{print $11}' | xargs dirname | uniq)

if [ `id -u` -ne 0 ] && ! groups $(whoami) | grep -q '\bdocker\b'; then
    echo "Run this script as root or through 'sudo'. Alternatively, add your user account to the 'docker' group. Script aborting."
    exit 1
fi

if [ -z "$PLEX_MEDIA_SERVER_DIR" ]; then
    echo "Plex Media Server is not running, unable to determine its directory. Script aborting."
    exit 1
fi

rm -rf /tmp/plexmediaserver_crack
mkdir /tmp/plexmediaserver_crack
cd /tmp/plexmediaserver_crack
wget https://gitgud.io/yuv420p10le/plexmediaserver_crack/-/raw/master/binaries/plexmediaserver_crack.so
docker cp $(which patchelf) $PLEX_CONTAINER_NAME:$PLEX_CONFIG_DIR/patchelf
docker cp plexmediaserver_crack.so $PLEX_CONTAINER_NAME:$PLEX_CONFIG_DIR/plexmediaserver_crack.so
docker exec $PLEX_CONTAINER_NAME ln -sf /config/plexmediaserver_crack.so $PLEX_MEDIA_SERVER_DIR/lib/plexmediaserver_crack.so
docker exec $PLEX_CONTAINER_NAME /config/patchelf --remove-needed plexmediaserver_crack.so $PLEX_MEDIA_SERVER_DIR/lib/libsoci_core.so
docker exec $PLEX_CONTAINER_NAME /config/patchelf --add-needed plexmediaserver_crack.so $PLEX_MEDIA_SERVER_DIR/lib/libsoci_core.so
docker restart $PLEX_CONTAINER_NAME
