#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/services.sh.
#
# The Supervisor API boundary is stubbed via a `bashio::api.supervisor` bash
# function so no real HTTP requests are made. The cache is isolated to a
# per-test temporary directory.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

# ---------------------------------------------------------------------------
# Canned JSON response used by most tests
# ---------------------------------------------------------------------------
SERVICE_JSON='{
  "host": "mqtt.local",
  "port": 1883,
  "ssl": false,
  "username": "testuser",
  "password": "testpass",
  "protocol": "3.1.1",
  "addon": "core_mosquitto"
}'

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ---------------------------------------------------------------------------
# bashio::services - base fetcher
# ---------------------------------------------------------------------------

@test "services calls GET /services/<name>" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' "${SERVICE_JSON}"
    }
    run bashio::services "mqtt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${SERVICE_JSON}" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /services/mqtt false" ]
}

@test "services extracts a string field by key" {
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    run bashio::services "mqtt" "host"
    [ "${status}" -eq 0 ]
    [ "${output}" = "mqtt.local" ]
}

@test "services extracts a numeric field by key" {
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    run bashio::services "mqtt" "port"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1883" ]
}

@test "services extracts a boolean field by key" {
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    run bashio::services "mqtt" "ssl"
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "services returns the literal null for a null field" {
    bashio::api.supervisor() {
        printf '%s' '{"host":null}'
    }
    run bashio::services "mqtt" "host"
    [ "${status}" -eq 0 ]
    [ "${output}" = "null" ]
}

@test "services returns empty output for an empty string field" {
    bashio::api.supervisor() {
        printf '%s' '{"host":""}'
    }
    run bashio::services "mqtt" "host"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "services returns each element of an array field" {
    bashio::api.supervisor() {
        printf '%s' '{"tags":["a","b","c"]}'
    }
    run bashio::services "mqtt" "tags"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"a"* ]]
    [[ "${output}" == *"b"* ]]
    [[ "${output}" == *"c"* ]]
}

@test "services returns empty output for an empty array field" {
    bashio::api.supervisor() {
        printf '%s' '{"tags":[]}'
    }
    run bashio::services "mqtt" "tags"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "services returns an object field as-is" {
    bashio::api.supervisor() {
        printf '%s' '{"config":{"key":"val"}}'
    }
    run bashio::services "mqtt" "config"
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.key')" = "val" ]
}

@test "services returns empty output for an empty object field" {
    bashio::api.supervisor() {
        printf '%s' '{"config":{}}'
    }
    run bashio::services "mqtt" "config"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "services uses a cache key per service name" {
    local call_file="${BATS_TEST_TMPDIR}/calls"
    printf '0' >"${call_file}"
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        printf '%s' "${SERVICE_JSON}"
    }
    # Call both without `run` so the cache state is shared.
    bashio::services "mqtt" >/dev/null
    bashio::services "mqtt" "host" >/dev/null
    # Second call for the same service must be served from cache.
    [ "$(cat "${call_file}")" -eq 1 ]

    # A different service must not collide with the first cache entry, so it
    # triggers a fresh API call and gets its own cache file.
    bashio::services "mysql" >/dev/null
    [ "$(cat "${call_file}")" -eq 2 ]
    [ -f "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]
    [ -f "${__BASHIO_CACHE_DIR}/service.info.mysql.cache" ]
}

@test "services propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::services "mqtt" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::services.available
# ---------------------------------------------------------------------------

@test "services.available returns success when the API call succeeds" {
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    run bashio::services.available "mqtt"
    [ "${status}" -eq 0 ]
}

@test "services.available returns failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::services.available "mqtt"
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::services.publish
# ---------------------------------------------------------------------------

@test "services.publish calls POST /services/<name> with the config" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    bashio::cache.flush_all
    run bashio::services.publish "mqtt" '{"host":"broker.local"}'
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = 'POST /services/mqtt {"host":"broker.local"}' ]
}

@test "services.publish flushes the cache" {
    # Prime the cache first.
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    bashio::services "mqtt" >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::services.publish "mqtt" '{"host":"new"}'
    # Cache directory must be gone after publish.
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "services.publish flushes the cache even when the API call fails" {
    # bashio::services.publish does not check the API return code; it calls
    # bashio::cache.flush_all after the API call regardless of its outcome.
    # When errexit is suppressed (as it is under `run`), the failing API call
    # does not abort the function, so the flush is still observed.
    # Prime the cache first.
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    bashio::services "mqtt" >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]

    # Now publish with a failing API stub; the cache must still be flushed.
    bashio::api.supervisor() { return 1; }
    run bashio::services.publish "mqtt" '{"host":"x"}'
    [ ! -e "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

# ---------------------------------------------------------------------------
# bashio::services.delete
# ---------------------------------------------------------------------------

@test "services.delete calls DELETE /services/<name>" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::services.delete "mqtt"
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = "DELETE /services/mqtt" ]
}

@test "services.delete flushes the cache" {
    # Prime the cache first.
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    bashio::services "mqtt" >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::services.delete "mqtt"
    # Cache directory must be gone after delete.
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "services.delete flushes the cache even when the API call fails" {
    # bashio::services.delete does not check the API return code; it calls
    # bashio::cache.flush_all after the API call regardless of its outcome.
    # When errexit is suppressed (as it is under `run`), the failing API call
    # does not abort the function, so the flush is still observed.
    # Prime the cache first.
    bashio::api.supervisor() { printf '%s' "${SERVICE_JSON}"; }
    bashio::services "mqtt" >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]

    # Now delete with a failing API stub; the cache must still be flushed.
    bashio::api.supervisor() { return 1; }
    run bashio::services.delete "mqtt"
    [ ! -e "${__BASHIO_CACHE_DIR}/service.info.mqtt.cache" ]
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}
