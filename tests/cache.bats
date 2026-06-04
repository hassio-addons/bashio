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

@test "cache.set fails if a stale entry cannot be removed" {
    # If the existing entry cannot be removed, the value must not be written
    # into an unknown target (for example a leftover symlink). A directory in
    # place of the cache file makes "rm -f" fail without stubbing rm (which
    # bats itself relies on for cleanup).
    mkdir -p "${__BASHIO_CACHE_DIR}/key.cache"
    run bashio::cache.set "key" "value"
    [ "${status}" -ne 0 ]
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

@test "cache.set rejects a key containing a slash and writes nothing" {
    run bashio::cache.set "sub/dir" "value"
    [ "${status}" -ne 0 ]
    [ ! -e "${__BASHIO_CACHE_DIR}/sub" ]
}

@test "cache.set rejects a path-traversal key without escaping the cache dir" {
    run bashio::cache.set "../escaped" "secret"
    [ "${status}" -ne 0 ]
    # Nothing must be written outside the cache directory.
    [ ! -e "${BATS_TEST_TMPDIR}/escaped.cache" ]
}

@test "cache.exists rejects an invalid key" {
    run bashio::cache.exists "../escaped"
    [ "${status}" -ne 0 ]
}

@test "cache.get rejects an invalid key" {
    run bashio::cache.get "bad/key"
    [ "${status}" -ne 0 ]
}

@test "cache.flush rejects an invalid key" {
    run bashio::cache.flush "../../etc/passwd"
    [ "${status}" -ne 0 ]
}

@test "cache.set rejects an empty key" {
    run bashio::cache.set "" "value"
    [ "${status}" -ne 0 ]
}

@test "cache.set accepts dotted, hyphen and underscore keys" {
    # The keys bashio itself uses (e.g. addons.<slug>.info, eth0 interfaces).
    bashio::cache.set "apps.core_ssh-2.info" "value"
    run bashio::cache.get "apps.core_ssh-2.info"
    [ "${status}" -eq 0 ]
    [ "${output}" = "value" ]
}
