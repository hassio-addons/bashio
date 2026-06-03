#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/network.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "network.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::network.reload || rc=$?
    [ "${rc}" -ne 0 ]
}
