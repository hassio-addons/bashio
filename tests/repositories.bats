#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/repositories.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "repository.add propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::repository.add "https://example.com/repository" || rc=$?
    [ "${rc}" -ne 0 ]
}
