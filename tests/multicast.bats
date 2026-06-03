#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/multicast.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "multicast.restart propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::multicast.restart || rc=$?
    [ "${rc}" -ne 0 ]
}
