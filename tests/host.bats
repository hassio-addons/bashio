#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/host.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "host.hostname propagates an API failure when setting" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::host.hostname "example" || rc=$?
    [ "${rc}" -ne 0 ]
}
