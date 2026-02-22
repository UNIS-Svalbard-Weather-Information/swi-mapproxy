ARG PYTHON_VERSION=3.13
ARG DEBIAN_VERSION=trixie
ARG MAPPROXY_VERSION=6.0.1
ARG MAPNIK_VERSION=4.0.7+ds-1

# Builder stage
FROM debian:${DEBIAN_VERSION} AS builder

ARG PYTHON_VERSION
ARG MAPPROXY_VERSION

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    git \
    patch \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download MapProxy source to apply the patch for proj4 issue with MapNik
WORKDIR /tmp
RUN git clone https://github.com/mapproxy/mapproxy.git && \
    cd mapproxy && \
    git checkout ${MAPPROXY_VERSION}

# Download and apply the patch
RUN curl -sSL https://salsa.debian.org/debian-gis-team/mapproxy/-/raw/master/debian/patches/mapnik.patch -o /tmp/mapnik.patch && \
    cd /tmp/mapproxy && \
    patch -p1 < /tmp/mapnik.patch

# Install MapProxy from the patched source
WORKDIR /tmp/mapproxy
RUN pip install --no-cache-dir --break-system-packages .

# Install other Python packages
RUN pip install --no-cache-dir --break-system-packages uwsgi azure-storage-blob boto3 redis

# Copy configuration files and scripts
COPY config.py /mapproxy/
COPY uwsgi.ini.default /mapproxy/
COPY mapproxy.yaml.default /mapproxy/user_config/
COPY run.sh /mapproxy/
COPY health-check.sh /mapproxy/

# Runtime stage
FROM debian:trixie-slim

ARG PYTHON_VERSION
ARG MAPNIK_VERSION

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    libpython${PYTHON_VERSION} \
    libmapnik-dev=${MAPNIK_VERSION} \
    mapnik-utils=${MAPNIK_VERSION} \
    python3-mapnik \
    libgeos-dev \
    libgdal-dev \
    libxml2-dev \
    libxslt-dev \
    curl \
    ca-certificates \
    git \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages and application files from the builder stage
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/dist-packages /usr/local/lib/python${PYTHON_VERSION}/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /mapproxy /mapproxy

# Create a non-root user and group
RUN useradd -m mapproxy && \
    mkdir -p /mapproxy/config /mapproxy/user_config /mapproxy/data /mapproxy/metadata /mapproxy/mbtiles && \
    chown -R mapproxy:mapproxy /mapproxy

# Set permissions for scripts
RUN chmod +x /mapproxy/run.sh /mapproxy/health-check.sh

# Switch to the non-root user
USER mapproxy
WORKDIR /mapproxy

# Expose ports
EXPOSE 8080
EXPOSE 9191

CMD ["/mapproxy/run.sh"]
