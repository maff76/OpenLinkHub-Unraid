#!/bin/bash
set -e

IMAGE_VERSION_FILE="/usr/share/openlinkhub/.image_version"
APPDATA_VERSION_FILE="/opt/OpenLinkHub/.image_version"

# Get image version
if [ -f "$IMAGE_VERSION_FILE" ]; then
	IMAGE_VERSION=$(cat "$IMAGE_VERSION_FILE")
else
	IMAGE_VERSION="0"
fi

# Get appdata version (if exists)
if [ -f "$APPDATA_VERSION_FILE" ]; then
	APPDATA_VERSION=$(cat "$APPDATA_VERSION_FILE")
else
	APPDATA_VERSION="0"
fi

# Check if first run (folders don't exist) or image has changed
if [ ! -d /opt/OpenLinkHub/database ] || [ ! -d /opt/OpenLinkHub/static ] || [ ! -d /opt/OpenLinkHub/web ] || [ "$IMAGE_VERSION" != "$APPDATA_VERSION" ]; then
	if [ "$IMAGE_VERSION" != "$APPDATA_VERSION" ]; then
		echo "Image version changed. Updating appdata folders..."
	else
		echo "First run detected. Initializing appdata folders..."
	fi
	
	# Copy/update folders from image to appdata
	cp -r /usr/share/openlinkhub/database /opt/OpenLinkHub/database.new
	cp -r /usr/share/openlinkhub/static /opt/OpenLinkHub/static.new
	cp -r /usr/share/openlinkhub/web /opt/OpenLinkHub/web.new
	
	# If old versions exist, merge them (keep user changes but add new files)
	if [ -d /opt/OpenLinkHub/database ]; then
		rsync -av --ignore-existing /opt/OpenLinkHub/database/ /opt/OpenLinkHub/database.new/ || true
		rm -rf /opt/OpenLinkHub/database
	fi
	mv /opt/OpenLinkHub/database.new /opt/OpenLinkHub/database
	
	if [ -d /opt/OpenLinkHub/static ]; then
		rsync -av --ignore-existing /opt/OpenLinkHub/static/ /opt/OpenLinkHub/static.new/ || true
		rm -rf /opt/OpenLinkHub/static
	fi
	mv /opt/OpenLinkHub/static.new /opt/OpenLinkHub/static
	
	if [ -d /opt/OpenLinkHub/web ]; then
		rsync -av --ignore-existing /opt/OpenLinkHub/web/ /opt/OpenLinkHub/web.new/ || true
		rm -rf /opt/OpenLinkHub/web
	fi
	mv /opt/OpenLinkHub/web.new /opt/OpenLinkHub/web
	
	# Update appdata version file
	cp "$IMAGE_VERSION_FILE" "$APPDATA_VERSION_FILE"
	
	echo "Appdata folders initialized/updated successfully"
else
	echo "Image version unchanged and folders exist. Skipping update."
fi

# Fix permissions on appdata folder - unrestricted access
chmod -R 777 /opt/OpenLinkHub
find /opt/OpenLinkHub -type d -exec chmod 777 {} \;
find /opt/OpenLinkHub -type f -exec chmod 666 {} \;

exec /usr/local/bin/OpenLinkHub
