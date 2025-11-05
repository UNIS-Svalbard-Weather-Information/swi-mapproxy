# SWI MapProxy

This repository contains the Docker setup and MapProxy configuration for Svalbard Weather Information (SWI) map services.

## Overview

MapProxy is an open-source proxy for geospatial data that caches, accelerates, and transforms data from existing map services. This configuration is specifically tailored for SWI services, including Mapnik for map rendering.

## Usage

The service can be started using Docker:

```bash
docker build -t swi-mapproxy .
docker run -p 8080:8080 -p 9191:9191 swi-mapproxy
```

## Requirements

- Docker
- Git (for configuration repository)

## Configuration

The service can be configured using:

- Environment variable `SWI_MAPPROXY_CONFIG_REPO` for custom repository URL
- Custom configuration files in `/mapproxy/user_config/`
- Default configurations if no custom settings are provided

## Components

- MapProxy for map service caching and transformation
- Mapnik for map rendering
- uWSGI as the application server
- Python 3 as the runtime environment

## License

See the LICENSE file for details.
