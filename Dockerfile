# Use the smallest Debian base image
FROM debian:latest

# Install Python, pip, and Git
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    gettext \
    git && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3 as the default Python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Verify installations
RUN python --version && \
    pip --version && \
    git --version

# Install MapNik and its Python bindings
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libmapnik-dev \
    mapnik-utils \
    python3-mapnik \
    && rm -rf /var/lib/apt/lists/*

# Install MapProxy and its dependencies
RUN apt-get update && \
    apt-get install libgeos-dev libgdal-dev libxml2-dev libxslt-dev mapproxy -y && \
    rm -rf /var/lib/apt/lists/*
# pip install --no-cache-dir --break-system-packages MapProxy azure-storage-blob boto3 redis

# Install uWSGI
RUN pip install --no-cache-dir --break-system-packages uwsgi

# Create a non-root user and group
RUN useradd -m mapproxy && \
    mkdir -p /mapproxy/config /mapproxy/user_config /mapproxy/data /mapproxy/metadata /mapproxy/mbtiles && \
    chown -R mapproxy:mapproxy /mapproxy

# Switch to the non-root user
USER mapproxy
WORKDIR /mapproxy

COPY run.sh /mapproxy/
RUN chmod +x /mapproxy/run.sh

# Copy default MapProxy configuration files
COPY config.py /mapproxy/
COPY uwsgi.ini.default /mapproxy/
COPY mapproxy.yaml.default /mapproxy/user_config/

# RUN if [ -d /mapproxy/user_config ] && [ "$(ls -A /mapproxy/user_config)" ]; then \
#     ln -s /mapproxy/user_config/* /mapproxy/config/; \
#     fi


# Expose the default MapProxy port and start uWSGI with the provided configuration
EXPOSE 8080
EXPOSE 9191

CMD ["/mapproxy/run.sh"]
