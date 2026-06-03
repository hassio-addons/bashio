#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/observer.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "observer module is loaded by bashio" {
    run type -t bashio::observer.update
    [ "${status}" -eq 0 ]
    [ "${output}" = "function" ]
}

@test "observer.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::observer.update || rc=$?
    [ "${rc}" -ne 0 ]
}
