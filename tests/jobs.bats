#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/jobs.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "jobs.reset propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::jobs.reset || rc=$?
    [ "${rc}" -ne 0 ]
}
