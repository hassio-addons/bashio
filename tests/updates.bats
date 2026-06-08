#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/updates.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::updates` fetcher, jq filtering, and caching run. The cache is pointed
# at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

UPDATES_JSON='{"available_updates":[{"update_type":"core","version_latest":"2"}]}'

# ------------------------------------------------------------------------------
# bashio::updates (fetcher)
# ------------------------------------------------------------------------------

@test "updates calls GET /available_updates" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' "${UPDATES_JSON}"
    }
    run bashio::updates
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /available_updates false" ]
    [ "${output}" = "${UPDATES_JSON}" ]
}

@test "updates applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' "${UPDATES_JSON}"; }
    run bashio::updates 'updates.available.type' '.available_updates[0].update_type'
    [ "${status}" -eq 0 ]
    [ "${output}" = "core" ]
}

@test "updates returns cached data on a second call without hitting the API" {
    local call_file="${BATS_TEST_TMPDIR}/calls"
    printf '0' >"${call_file}"
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        printf '%s' "${UPDATES_JSON}"
    }
    bashio::updates >/dev/null
    bashio::updates >/dev/null
    [ "$(cat "${call_file}")" -eq 1 ]
}

@test "updates propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::updates || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "updates propagates a jq filter failure" {
    bashio::api.supervisor() { printf '%s' "${UPDATES_JSON}"; }
    rc=0
    bashio::updates 'updates.available.bad' 'INVALID_FILTER_!!!' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "updates with the base key and a filter does not corrupt the base blob" {
    bashio::api.supervisor() { printf '%s' "${UPDATES_JSON}"; }
    run bashio::updates 'updates.available' '.available_updates[0].update_type'
    [ "${status}" -eq 0 ]
    [ "${output}" = "core" ]
    run bashio::cache.get 'updates.available'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.available_updates[0].update_type')" = "core" ]
}

# ------------------------------------------------------------------------------
# bashio::updates.refresh
# ------------------------------------------------------------------------------

@test "updates.refresh posts to the refresh endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::updates.refresh
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /refresh_updates" ]
}

@test "updates.refresh propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::updates.refresh || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "updates.refresh flushes the cache after a successful refresh" {
    bashio::cache.set 'updates.available' 'stale'
    bashio::api.supervisor() { return 0; }
    run bashio::updates.refresh
    [ "${status}" -eq 0 ]
    run bashio::cache.exists 'updates.available'
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::updates.reload
# ------------------------------------------------------------------------------

@test "updates.reload posts to the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::updates.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /reload_updates" ]
}

@test "updates.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::updates.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "updates.reload flushes the cache after a successful reload" {
    bashio::cache.set 'updates.available' 'stale'
    bashio::api.supervisor() { return 0; }
    run bashio::updates.reload
    [ "${status}" -eq 0 ]
    run bashio::cache.exists 'updates.available'
    [ "${status}" -ne 0 ]
}
