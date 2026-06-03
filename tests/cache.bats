#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/cache.sh (the on-disk key/value cache).
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "cache.set then cache.get round-trips a value" {
    bashio::cache.set "key" "value"
    run bashio::cache.get "key"
    [ "${status}" -eq 0 ]
    [ "${output}" = "value" ]
}

@test "cache.get fails for an unknown key" {
    run bashio::cache.get "missing"
    [ "${status}" -ne 0 ]
}

@test "cache.set creates the cache directory with owner-only permissions" {
    # The cache can hold secrets, so the directory must not be accessible to
    # other users in the container. Force a permissive umask first, so the test
    # proves the result does not depend on the ambient umask.
    umask 022
    bashio::cache.set "key" "value"
    [ -d "${__BASHIO_CACHE_DIR}" ]
    [ "$(stat -c '%a' "${__BASHIO_CACHE_DIR}")" = "700" ]
}

@test "cache.set tightens permissions on an existing cache directory" {
    # A directory left behind by an older version (or another process) with
    # broader permissions must be restricted before secrets are written into it.
    mkdir -p "${__BASHIO_CACHE_DIR}"
    chmod 0755 "${__BASHIO_CACHE_DIR}"
    bashio::cache.set "key" "value"
    [ "$(stat -c '%a' "${__BASHIO_CACHE_DIR}")" = "700" ]
}
