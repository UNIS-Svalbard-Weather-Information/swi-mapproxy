ARG PYTHON_VERSION=3.13
ARG DEBIAN_VERSION=trixie

# Builder stage
FROM debian:${DEBIAN_VERSION}-slim AS builder

ARG PYTHON_VERSION

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install uWSGI and other Python packages
RUN pip install --no-cache-dir --break-system-packages uwsgi MapProxy==6.0.1 azure-storage-blob boto3 redis

# Print the site-packages path for Python 3.13
RUN python${PYTHON_VERSION} -c "import site; print(site.getsitepackages())"

# Copy configuration files and scripts
COPY config.py /mapproxy/
COPY uwsgi.ini.default /mapproxy/
COPY mapproxy.yaml.default /mapproxy/user_config/
COPY run.sh /mapproxy/
COPY health-check.sh /mapproxy/

# Runtime stage
FROM debian:trixie-slim

ARG PYTHON_VERSION

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    libpython${PYTHON_VERSION} \
    libmapnik-dev \
    mapnik-utils \
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
