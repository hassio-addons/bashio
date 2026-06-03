#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/dns.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "dns.restart propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::dns.restart || rc=$?
    [ "${rc}" -ne 0 ]
}
