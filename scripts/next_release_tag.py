#!/usr/bin/env python3
"""Compose the next image release tag for swi-mapproxy.

Tag shape: ``<debian>-p<python>-mp<mapproxy>-<major>.<minor>.<patch>``, for example
``trixie-p3.13-mp7.0.0-0.0.13``.

The first three parts are read from the ARGs of the Dockerfile, so bumping MapProxy,
Python or Debian in a pull request changes the tag by itself. The trailing number is an
image revision that only ever increases across *all* existing tags, whatever their
other parts: swi-production-deployment orders images by it (see its
.github/version-updater.yml), and older tags are plain ``0.0.N``.

Usage: next_release_tag.py Dockerfile < existing-tags.txt
"""

import re
import sys

REVISION = r"(?P<rev>\d+\.\d+\.\d+)"
PLAIN_TAG = re.compile(rf"^{REVISION}$")
SCHEME_TAG = re.compile(rf"^[a-z]+-p\d+\.\d+-mp\d+\.\d+\.\d+-{REVISION}$")

ARG_PATTERNS = {
    "debian": (r"^ARG DEBIAN_VERSION=([a-z]+)$", "DEBIAN_VERSION"),
    "python": (r"^ARG PYTHON_VERSION=(\d+\.\d+)$", "PYTHON_VERSION"),
    "mapproxy": (r"^ARG MAPPROXY_VERSION=(\d+\.\d+\.\d+)$", "MAPPROXY_VERSION"),
}


def read_args(dockerfile_text):
    """Return the debian, python and mapproxy versions declared in the Dockerfile."""
    found = {}
    for key, (pattern, name) in ARG_PATTERNS.items():
        match = re.search(pattern, dockerfile_text, re.MULTILINE)
        if not match:
            raise ValueError(f"Dockerfile has no usable 'ARG {name}=' line")
        found[key] = match.group(1)
    return found


def latest_revision(tags):
    """Highest (major, minor, patch) among plain and scheme tags, or (0, 0, 0)."""
    best = (0, 0, 0)
    for tag in tags:
        tag = tag.strip()
        match = PLAIN_TAG.match(tag) or SCHEME_TAG.match(tag)
        if match:
            best = max(best, tuple(int(x) for x in match["rev"].split(".")))
    return best


def next_tag(dockerfile_text, existing_tags):
    args = read_args(dockerfile_text)
    major, minor, patch = latest_revision(existing_tags)
    return (
        f"{args['debian']}-p{args['python']}-mp{args['mapproxy']}"
        f"-{major}.{minor}.{patch + 1}"
    )


def main(argv):
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    with open(argv[1], encoding="utf-8") as handle:
        dockerfile_text = handle.read()
    try:
        print(next_tag(dockerfile_text, sys.stdin.read().splitlines()))
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
