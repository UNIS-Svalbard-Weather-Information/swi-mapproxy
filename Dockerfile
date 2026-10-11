ARG PYTHON_VERSION=3.13
ARG DEBIAN_VERSION=trixie
ARG MAPPROXY_VERSION=7.0.0
# Commit of the MAPPROXY_VERSION tag: the build checks out the commit, not the movable tag
ARG MAPPROXY_COMMIT=49de7e7f5ab804da2b90c813e78c602931cad9a5
ARG MAPNIK_VERSION=4.0.7+ds-1

# Dependency resolution: MapProxy's dependencies and the extra packages, from uv.lock
FROM astral/uv:python3.13-bookworm-slim AS uv
WORKDIR /swi
COPY pyproject.toml uv.lock ./
# MapProxy itself is installed from the patched source below, not from the lock
RUN uv export --frozen --no-emit-project --no-emit-package mapproxy -o requirements.txt

# Builder stage
FROM debian:${DEBIAN_VERSION} AS builder

ARG PYTHON_VERSION
ARG MAPPROXY_VERSION
ARG MAPPROXY_COMMIT

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    git \
    patch \
    && rm -rf /var/lib/apt/lists/*

# Download MapProxy source to apply the patch for proj4 issue with MapNik
WORKDIR /tmp
RUN git clone https://github.com/mapproxy/mapproxy.git && \
    cd mapproxy && \
    git checkout --detach ${MAPPROXY_COMMIT} && \
    echo "MapProxy ${MAPPROXY_VERSION} at $(git rev-parse HEAD)"

# Apply the patch, vendored from Debian's mapproxy packaging (patches/mapnik.patch)
COPY patches/mapnik.patch /tmp/mapnik.patch
RUN cd /tmp/mapproxy && patch -p1 < /tmp/mapnik.patch

# Install the locked Python dependencies (hash-checked), then MapProxy from the
# patched source without resolving anything further
COPY --from=uv /swi/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --break-system-packages --require-hashes -r /tmp/requirements.txt
WORKDIR /tmp/mapproxy
RUN pip install --no-cache-dir --break-system-packages --no-deps .

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
