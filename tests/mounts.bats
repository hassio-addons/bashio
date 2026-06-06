#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/mounts.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::mounts` fetcher, jq filtering, and caching run. The cache is pointed
# at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

# ---------------------------------------------------------------------------
# Canned JSON response used by most tests
# ---------------------------------------------------------------------------
MOUNTS_JSON='{
  "default_backup_mount": "my_share",
  "mounts": [
    {"name": "my_share", "type": "cifs", "usage": "backup", "state": "active"},
    {"name": "media_nas", "type": "nfs", "usage": "media", "state": "active"}
  ]
}'

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ---------------------------------------------------------------------------
# bashio::mounts - base fetcher
# ---------------------------------------------------------------------------

@test "mounts fetches the info endpoint and returns the raw object by default" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' "${MOUNTS_JSON}"
    }
    run bashio::mounts
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /mounts false" ]
    # No default filter, so the whole mounts object is returned (use
    # bashio::mounts.list for names). Caching the unfiltered blob under the
    # default key must not corrupt the shared mounts.info cache.
    [ "$(printf '%s' "${output}" | jq -r '.mounts[0].name')" = "my_share" ]
}

@test "a bare mounts call leaves the mounts.info cache as the full object" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    # A bare call (default cache key + no filter) must cache the full blob under
    # mounts.info, not a filtered value, so later getters still get valid JSON.
    bashio::mounts >/dev/null
    run bashio::cache.get 'mounts.info'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.mounts[0].name')" = "my_share" ]
}

@test "mounts applies a custom jq filter to the info response" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    run bashio::mounts 'mounts.info.default' '.default_backup_mount'
    [ "${status}" -eq 0 ]
    [ "${output}" = "my_share" ]
}

@test "mounts reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::mounts
    [ "${status}" -ne 0 ]
}

@test "mounts serves a previously cached value without calling the API" {
    bashio::cache.set 'mounts.info.cached' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::mounts 'mounts.info.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ---------------------------------------------------------------------------
# bashio::mounts.list
# ---------------------------------------------------------------------------

@test "mounts.list lists the configured mount names" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    run bashio::mounts.list
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "my_share" ]
    [ "${lines[1]}" = "media_nas" ]
}

@test "mounts.list propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::mounts.list
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::mounts.default_backup_mount
# ---------------------------------------------------------------------------

@test "mounts.default_backup_mount extracts the default backup mount" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    run bashio::mounts.default_backup_mount
    [ "${status}" -eq 0 ]
    [ "${output}" = "my_share" ]
}

@test "mounts.default_backup_mount propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::mounts.default_backup_mount
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::mounts.create
# ---------------------------------------------------------------------------

@test "mounts.create calls POST /mounts with the mount definition" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::mounts.create '{"name":"my_share","type":"cifs"}'
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = 'POST /mounts {"name":"my_share","type":"cifs"}' ]
}

@test "mounts.create flushes the cache" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::mounts.create '{"name":"new"}'
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "mounts.create propagates an API failure" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    run bashio::mounts.create '{"name":"x"}'
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /mounts {"name":"x"}' ]
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]
}

@test "mounts.create does not log the mount credentials" {
    # A CIFS/NFS mount definition carries a username and password; these must
    # not reach the trace log.
    logged=""
    bashio::log.trace() { logged+=" $*"; }
    bashio::api.supervisor() { return 0; }
    bashio::mounts.create '{"name":"share","username":"admin","password":"hunter2"}'
    [[ "${logged}" != *"hunter2"* ]]
    [[ "${logged}" != *"admin"* ]]
}

# ---------------------------------------------------------------------------
# bashio::mounts.options
# ---------------------------------------------------------------------------

@test "mounts.options calls POST /mounts/options with the options" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::mounts.options '{"default_backup_mount":"my_share"}'
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = 'POST /mounts/options {"default_backup_mount":"my_share"}' ]
}

@test "mounts.options flushes the cache" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::mounts.options '{"default_backup_mount":null}'
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "mounts.options propagates an API failure" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    run bashio::mounts.options '{"default_backup_mount":"x"}'
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /mounts/options {"default_backup_mount":"x"}' ]
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]
}

@test "mounts.options does not log the options payload" {
    # The options object can carry mount credentials, so the payload must not
    # reach the trace log.
    logged=""
    bashio::log.trace() { logged+=" $*"; }
    bashio::api.supervisor() { return 0; }
    bashio::mounts.options '{"name":"share","password":"hunter2"}'
    [[ "${logged}" != *"hunter2"* ]]
}

# ---------------------------------------------------------------------------
# bashio::mount.reload
# ---------------------------------------------------------------------------

@test "mount.reload calls POST /mounts/<name>/reload" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::mount.reload "my_share"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /mounts/my_share/reload" ]
}

@test "mount.reload flushes the cache" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::mount.reload "my_share"
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "mount.reload propagates an API failure" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    run bashio::mount.reload "my_share"
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /mounts/my_share/reload" ]
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]
}

# ---------------------------------------------------------------------------
# bashio::mount.delete
# ---------------------------------------------------------------------------

@test "mount.delete calls DELETE /mounts/<name>" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::mount.delete "my_share"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /mounts/my_share" ]
}

@test "mount.delete flushes the cache" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::mount.delete "my_share"
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "mount.delete propagates an API failure" {
    bashio::api.supervisor() { printf '%s' "${MOUNTS_JSON}"; }
    bashio::mounts >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]

    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    run bashio::mount.delete "my_share"
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /mounts/my_share" ]
    [ -f "${__BASHIO_CACHE_DIR}/mounts.info.cache" ]
}
