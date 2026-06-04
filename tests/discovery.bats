#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/discovery.sh.
#
# The Supervisor API boundary is stubbed via a `bashio::api.supervisor` bash
# function so no real HTTP requests are made. The cache is isolated to a
# per-test temporary directory.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ---------------------------------------------------------------------------
# bashio::discovery
# ---------------------------------------------------------------------------

@test "discovery calls POST /discovery with service and config payload" {
    # Capture the exact argument string so method, resource, payload and filter
    # are all validated in their correct positions, not as loose substrings.
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '"abc-uuid"'
    }
    # Build the exact payload the function is expected to send, using the same
    # helper, so the comparison stays robust to JSON key ordering.
    expected_payload=$(
        bashio::var.json \
            service "mqtt" \
            config "^"'{"host":"broker.local","port":1883}'
    )
    run bashio::discovery "mqtt" '{"host":"broker.local","port":1883}'
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = "POST /discovery ${expected_payload} .uuid" ]
}

@test "discovery payload contains service name" {
    bashio::api.supervisor() {
        # Write the payload argument (3rd positional) to a file for inspection.
        printf '%s' "$3" >"${BATS_TEST_TMPDIR}/payload"
        printf '%s' '"test-uuid"'
    }
    bashio::discovery "myservice" '{"key":"value"}' >/dev/null
    payload="$(cat "${BATS_TEST_TMPDIR}/payload")"
    [ "$(printf '%s' "${payload}" | jq -r '.service')" = "myservice" ]
}

@test "discovery payload embeds the config object" {
    bashio::api.supervisor() {
        printf '%s' "$3" >"${BATS_TEST_TMPDIR}/payload"
        printf '%s' '"test-uuid"'
    }
    bashio::discovery "myservice" '{"host":"broker.local","port":1883}' >/dev/null
    payload="$(cat "${BATS_TEST_TMPDIR}/payload")"
    [ "$(printf '%s' "${payload}" | jq -r '.config.host')" = "broker.local" ]
    [ "$(printf '%s' "${payload}" | jq -r '.config.port')" = "1883" ]
}

@test "discovery returns the uuid from the API response" {
    bashio::api.supervisor() { printf '%s' 'abc-def-uuid'; }
    run bashio::discovery "mqtt" '{"host":"x"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = "abc-def-uuid" ]
}

@test "discovery flushes the cache after publishing" {
    # Prime the cache first with a dummy key.
    bashio::cache.set "some.key" "some.value"
    [ -f "${BATS_TEST_TMPDIR}/cache/some.key.cache" ]

    bashio::api.supervisor() { printf '%s' '"new-uuid"'; }
    bashio::discovery "mqtt" '{"host":"x"}' >/dev/null
    # Cache directory must be gone after publish.
    [ ! -d "${BATS_TEST_TMPDIR}/cache" ]
}

@test "discovery masks API failure: cache is flushed and exit status is 0" {
    # bashio::discovery does not propagate the API return code: its return
    # status is whatever bashio::cache.flush_all returns. An API failure is
    # only masked when the caller suppresses errexit (as here, with `|| rc=$?`).
    # Prime a cache entry to confirm the flush still runs even when the API
    # call fails, and record the call so we can prove the API was attempted.
    bashio::cache.set "some.key" "before-failure"
    [ -f "${BATS_TEST_TMPDIR}/cache/some.key.cache" ]

    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    rc=0
    bashio::discovery "mqtt" '{"host":"x"}' >/dev/null || rc=$?
    [ "${rc}" -eq 0 ]
    # The failing Supervisor call must still have been attempted.
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [[ "${call}" == "POST /discovery "* ]]
    # The cache must be gone, proving flush_all ran despite the API failure.
    [ ! -d "${BATS_TEST_TMPDIR}/cache" ]
}

# ---------------------------------------------------------------------------
# bashio::discovery.delete
# ---------------------------------------------------------------------------

@test "discovery.delete calls DELETE /discovery/<uuid>" {
    # Capture the exact argument string so method and resource path are
    # validated in their correct positions, not as loose substrings.
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::discovery.delete "abc-def-uuid"
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = "DELETE /discovery/abc-def-uuid" ]
}

@test "discovery.delete passes the uuid in the path" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    bashio::discovery.delete "some-other-uuid"
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [[ "${call}" == *"/discovery/some-other-uuid"* ]]
}

@test "discovery.delete flushes the cache" {
    bashio::cache.set "some.key" "some.value"
    [ -f "${BATS_TEST_TMPDIR}/cache/some.key.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::discovery.delete "abc-def-uuid"
    [ ! -d "${BATS_TEST_TMPDIR}/cache" ]
}

@test "discovery.delete masks API failure: cache is flushed and exit status is 0" {
    # bashio::discovery.delete does not propagate the API return code: its
    # return status is whatever bashio::cache.flush_all returns. An API failure
    # is only masked when the caller suppresses errexit (as here, with
    # `|| rc=$?`). Prime a cache entry to confirm the flush still runs even when
    # the API call fails, and record the call so we can prove it was attempted.
    bashio::cache.set "some.key" "before-failure"
    [ -f "${BATS_TEST_TMPDIR}/cache/some.key.cache" ]

    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    rc=0
    bashio::discovery.delete "abc-def-uuid" || rc=$?
    [ "${rc}" -eq 0 ]
    # The failing Supervisor call must still have been attempted.
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = "DELETE /discovery/abc-def-uuid" ]
    # The cache must be gone, proving flush_all ran despite the API failure.
    [ ! -d "${BATS_TEST_TMPDIR}/cache" ]
}
