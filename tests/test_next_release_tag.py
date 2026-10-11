import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))

from next_release_tag import latest_revision, next_tag  # noqa: E402

DOCKERFILE = """\
ARG PYTHON_VERSION=3.13
ARG DEBIAN_VERSION=trixie
ARG MAPPROXY_VERSION=7.0.0
ARG MAPPROXY_COMMIT=49de7e7f5ab804da2b90c813e78c602931cad9a5
"""

# The pattern swi-production-deployment uses to order MapProxy images
# (.github/version-updater.yml); the generated tags must keep matching it.
DEPLOYMENT_PATTERN = re.compile(
    r"^trixie-p\d+\.\d+-mp\d+\.\d+\.\d+-(?P<version>\d+\.\d+\.\d+)$"
)


class NextTagTest(unittest.TestCase):
    def test_continues_the_revision_after_the_last_release(self):
        tags = ["trixie-p3.13-mp6.0.1-0.0.12", "0.0.11", "0.0.0"]
        self.assertEqual(next_tag(DOCKERFILE, tags), "trixie-p3.13-mp7.0.0-0.0.13")

    def test_orders_revisions_numerically_not_as_text(self):
        tags = ["0.0.9", "0.0.10", "trixie-p3.13-mp6.0.1-0.0.2"]
        self.assertEqual(latest_revision(tags), (0, 0, 10))

    def test_counts_plain_and_scheme_tags_together(self):
        tags = ["0.0.30", "trixie-p3.13-mp6.0.1-0.0.12"]
        self.assertEqual(next_tag(DOCKERFILE, tags), "trixie-p3.13-mp7.0.0-0.0.31")

    def test_ignores_unrelated_tags(self):
        tags = ["latest", "v1", "trixie-p3.13-mp6.0.1-0.0.12-DEV", "0.0.5", " "]
        self.assertEqual(latest_revision(tags), (0, 0, 5))

    def test_first_release_starts_at_one(self):
        self.assertEqual(next_tag(DOCKERFILE, []), "trixie-p3.13-mp7.0.0-0.0.1")

    def test_new_mapproxy_version_keeps_the_counter_going(self):
        bumped = DOCKERFILE.replace("MAPPROXY_VERSION=7.0.0", "MAPPROXY_VERSION=7.1.0")
        tags = ["trixie-p3.13-mp7.0.0-0.0.13"]
        self.assertEqual(next_tag(bumped, tags), "trixie-p3.13-mp7.1.0-0.0.14")

    def test_generated_tag_matches_the_deployment_pattern(self):
        tag = next_tag(DOCKERFILE, ["0.0.12"])
        match = DEPLOYMENT_PATTERN.match(tag)
        self.assertIsNotNone(match)
        self.assertEqual(match["version"], "0.0.13")

    def test_missing_arg_is_an_error_not_a_guess(self):
        broken = DOCKERFILE.replace("ARG MAPPROXY_VERSION=7.0.0\n", "")
        with self.assertRaises(ValueError):
            next_tag(broken, [])

    def test_unexpected_arg_format_is_an_error(self):
        broken = DOCKERFILE.replace("trixie", "13.1 ")
        with self.assertRaises(ValueError):
            next_tag(broken, [])


if __name__ == "__main__":
    unittest.main()
