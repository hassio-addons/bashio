#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/addons.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "addons.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::addons.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::addon.update "example" || rc=$?
    [ "${rc}" -ne 0 ]
}
