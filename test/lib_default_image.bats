#!/usr/bin/env bats
#
# Tests for lib/default_image (single source of truth for the default Quibble image).

@test "default_image: sets QUIBBLE_DEFAULT_IMAGE to a releng quibble image" {
  run bash -c '
    . lib/default_image
    echo "$QUIBBLE_DEFAULT_IMAGE"
  '
  [ "$status" -eq 0 ]
  # Distro-agnostic: assert the image shape, not the Debian codename, so a future
  # base bump (e.g. bookworm -> trixie) updates only lib/default_image and never this test.
  [[ "$output" == "docker-registry.wikimedia.org/releng/quibble-"*"-php83:latest" ]]
}
