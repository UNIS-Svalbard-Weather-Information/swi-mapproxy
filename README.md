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

If needed to trigger a reload from WSGI, it is possible to `touch /mapproxy/data/reload.trigger`

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

## Releases

Every merge to `main` that changes what goes into the image (`Dockerfile`, `pyproject.toml`,
`uv.lock`, `patches/`, the config and script files copied into the image) builds, pushes and
releases it automatically, see `.github/workflows/release.yml`. Documentation and CI-only
changes do not release. To release without a code change (for example to pick up base image
fixes), run the **Release** workflow from the Actions tab.

Images are tagged `<debian>-p<python>-mp<mapproxy>-<revision>`, for example
`trixie-p3.13-mp7.0.0-0.0.13`:

- the first three parts come from the `DEBIAN_VERSION`, `PYTHON_VERSION` and `MAPPROXY_VERSION`
  ARGs in the `Dockerfile`, so bumping one of them in a pull request changes the tag;
- the revision (`0.0.N`) increases with every release, whatever the other parts are.
  `swi-production-deployment` orders MapProxy images by it, so it must never go down.

release-please cannot produce this scheme, so `scripts/next_release_tag.py` composes the tag
(unit tests in `tests/`). A `latest` tag is pushed alongside each release. Tags pushed by hand
still build through `.github/workflows/docker-build-push.yml`, which is how `DEV` builds are made.

When bumping MapProxy, change `MAPPROXY_VERSION` and `MAPPROXY_COMMIT` (the commit of that tag)
in the `Dockerfile` and `mapproxy==` in `pyproject.toml`, then refresh `uv.lock`. MapProxy is
installed from source, so Dependabot does not track it: watch
<https://github.com/mapproxy/mapproxy/security/advisories> and the releases page.
