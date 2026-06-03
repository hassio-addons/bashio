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
    # The cache file itself must also be owner-only.
    [ "$(stat -c '%a' "${__BASHIO_CACHE_DIR}/key.cache")" = "600" ]
}

@test "cache.set tightens permissions on an existing cache directory" {
    # A directory left behind by an older version (or another process) with
    # broader permissions must be restricted before secrets are written into it.
    umask 022
    mkdir -p "${__BASHIO_CACHE_DIR}"
    chmod 0755 "${__BASHIO_CACHE_DIR}"
    bashio::cache.set "key" "value"
    [ "$(stat -c '%a' "${__BASHIO_CACHE_DIR}")" = "700" ]
    [ "$(stat -c '%a' "${__BASHIO_CACHE_DIR}/key.cache")" = "600" ]
}

@test "cache.set tightens permissions on an existing cache file" {
    # A cache file left behind with a permissive mode must not keep that mode
    # when a new value is written into it.
    umask 022
    mkdir -p "${__BASHIO_CACHE_DIR}"
    : >"${__BASHIO_CACHE_DIR}/key.cache"
    chmod 0644 "${__BASHIO_CACHE_DIR}/key.cache"
    bashio::cache.set "key" "value"
    [ "$(stat -c '%a' "${__BASHIO_CACHE_DIR}/key.cache")" = "600" ]
    run bashio::cache.get "key"
    [ "${output}" = "value" ]
}
