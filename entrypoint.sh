#!/bin/bash
set -e

# Copy/update folders from image to appdata only if they don't exist
[ ! -d /opt/OpenLinkHub/database ] && cp -r /usr/share/openlinkhub/database /opt/OpenLinkHub/
[ ! -d /opt/OpenLinkHub/static ] && cp -r /usr/share/openlinkhub/static /opt/OpenLinkHub/
[ ! -d /opt/OpenLinkHub/web ] && cp -r /usr/share/openlinkhub/web /opt/OpenLinkHub/

# Fix permissions on appdata folder - unrestricted access
chmod -R 777 /opt/OpenLinkHub
find /opt/OpenLinkHub -type d -exec chmod 777 {} \;
find /opt/OpenLinkHub -type f -exec chmod 666 {} \;

exec /usr/local/bin/OpenLinkHub
