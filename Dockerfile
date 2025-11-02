# Use the smallest Debian base image
FROM debian:latest

# Install Python, pip, and Git
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
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
    apt-get install libgeos-dev libgdal-dev libxml2-dev libxslt-dev -y && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --break-system-packages MapProxy



# Install uWSGI
RUN pip install --no-cache-dir --break-system-packages uwsgi

# Create folders for MapProxy configuration, cache and data
RUN mkdir -p /mapproxy/config /mapproxy/cache /mapproxy/data
WORKDIR /mapproxy

# Copy default MapProxy configuration files
COPY config.py /mapproxy/
COPY uwsgi.ini /mapproxy/
COPY mapproxy.yaml /mapproxy/config/

# Expose the default MapProxy port and start uWSGI with the provided configuration
EXPOSE 8080
EXPOSE 9191
CMD ["uwsgi", "--ini", "uwsgi.ini"]

# EXPOSE 8080
# CMD ["mapproxy-util", "serve-develop", "config/mapproxy.yaml"]


# # Use a Debian-based Python 3.11 slim image
# FROM python:3.11.14-slim AS build

# # Install only system dependencies (not available via pip)
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#     git \
#     libproj25 \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# # Install Python dependencies via pip
# RUN pip install --no-cache-dir \
#     pillow \
#     pyyaml \
#     mapnik

# # Clone and install pymapnik
# # RUN git clone https://github.com/mapnik/pymapnik.git && \
# #     cd pymapnik && \
# #     python setup.py install && \
# #     rm -rf /pymapnik

# # Verify Mapnik installation
# RUN python -c 'import mapnik; print("Mapnik is installed correctly!")' || \
#     (echo "Mapnik installation failed" && exit 1)

# # Install MapProxy
# RUN pip install --no-cache-dir mapproxy

# # Create and set the working directory
# WORKDIR /mapproxy

# # Final stage: use the build stage as the base
# FROM build

# # Expose the default MapProxy port
# EXPOSE 8080

# # Command to run MapProxy in development mode
# CMD ["mapproxy-util", "serve-develop", "mapproxy.yaml"]
