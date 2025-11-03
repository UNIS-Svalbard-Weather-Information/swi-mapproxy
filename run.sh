#!/bin/bash

echo "Starting MapProxy initialization script..."

# Set default repository if SWI_MAPPROXY_CONFIG_REPO is not defined
REPO_URL=${SWI_MAPPROXY_CONFIG_REPO:-"https://github.com/UNIS-Svalbard-Weather-Information/swi-mapproxy-configuration.git"}
echo "Using repository URL: $REPO_URL"

# Clone or update the configuration repository
if [ -d "/mapproxy/swi-mapproxy-configuration/.git" ]; then
    echo "Updating existing configuration repository..."
    cd /mapproxy/swi-mapproxy-configuration
    git pull
else
    echo "Cloning configuration repository..."
    git clone "$REPO_URL" /mapproxy/swi-mapproxy-configuration
fi

# Simlink uwsgi from user config, or config if it exists and default to the main one
echo "Setting up uwsgi configuration..."
if [ -f "/mapproxy/user_config/uwsgi.ini" ]; then
    echo "Using uwsgi configuration from user_config"
    ln -sf /mapproxy/user_config/uwsgi.ini /mapproxy/uwsgi.ini
elif [ -f "/mapproxy/swi-mapproxy-configuration/uwsgi.ini" ]; then
    echo "Using uwsgi configuration from repository"
    ln -sf /mapproxy/swi-mapproxy-configuration/uwsgi.ini /mapproxy/uwsgi.ini
else
    echo "Using default uwsgi configuration"
    ln -sf /mapproxy/uwsgi.ini.default /mapproxy/uwsgi.ini
fi

# Generate mapproxy.yaml configuration
echo "Setting up mapproxy configuration..."
if [ -f "/mapproxy/user_config/mapproxy.yaml" ]; then
    echo "Using mapproxy configuration from user_config"
    envsubst < /mapproxy/user_config/mapproxy.yaml > /mapproxy/config/mapproxy.yaml
elif [ -f "/mapproxy/swi-mapproxy-configuration/mapproxy.yaml" ]; then
    echo "Using mapproxy configuration from repository"
    envsubst < /mapproxy/swi-mapproxy-configuration/mapproxy.yaml > /mapproxy/config/mapproxy.yaml
else
    echo "Using default mapproxy configuration"
    envsubst < /mapproxy/mapproxy.yaml.default > /mapproxy/config/mapproxy.yaml
fi

# Copy Metadata if exists
if [ -d "/mapproxy/swi-mapproxy-configuration/metadata" ]; then
    echo "Copying metadata files..."
    cp -r /mapproxy/swi-mapproxy-configuration/metadata/* /mapproxy/metadata/
fi

echo "Starting MapProxy server..."
uwsgi --ini /mapproxy/uwsgi.ini