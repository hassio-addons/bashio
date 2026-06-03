#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/core.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "core.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::core.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "core.image propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::core.image "ghcr.io/example/image" || rc=$?
    [ "${rc}" -ne 0 ]
}
