#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/info.sh.
#
# The Supervisor API boundary is stubbed via a `bashio::api.supervisor` bash
# function so no real HTTP requests are made. The cache is isolated to a
# per-test temporary directory.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

# ---------------------------------------------------------------------------
# Canned JSON response used by most tests
# ---------------------------------------------------------------------------
INFO_JSON='{
  "supervisor": "2024.06.0",
  "homeassistant": "2024.6.1",
  "hassos": "12.3",
  "hostname": "homeassistant",
  "machine": "generic-x86-64",
  "arch": "amd64",
  "channel": "stable",
  "supported_arch": ["aarch64","amd64","armhf","armv7","i386"],
  "logging": "info",
  "timezone": "Europe/Amsterdam",
  "supported": true,
  "docker": "24.0.7",
  "operating_system": "Home Assistant OS",
  "state": "running"
}'

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ---------------------------------------------------------------------------
# bashio::info - base fetcher
# ---------------------------------------------------------------------------

@test "info calls GET /info" {
    local call_args="${BATS_TEST_TMPDIR}/args"
    bashio::api.supervisor() {
        printf '%s' "$*" >"${call_args}"
        printf '%s' "${INFO_JSON}"
    }
    run bashio::info
    [ "${status}" -eq 0 ]
    [ "${output}" = "${INFO_JSON}" ]
    # The base fetcher must forward the exact method, resource and raw flag.
    [ "$(cat "${call_args}")" = "GET /info false" ]
}

@test "info applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info 'test.filter.arch' '.arch'
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
}

@test "info returns cached data on a second call without hitting the API" {
    local call_file="${BATS_TEST_TMPDIR}/calls"
    printf '0' >"${call_file}"
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        printf '%s' "${INFO_JSON}"
    }
    bashio::info >/dev/null
    bashio::info >/dev/null
    [ "$(cat "${call_file}")" -eq 1 ]
}

@test "info propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "info propagates a jq filter failure" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    # An invalid jq expression causes bashio::jq to fail.
    rc=0
    bashio::info 'test.bad.filter' 'INVALID_FILTER_!!!' || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.supervisor
# ---------------------------------------------------------------------------

@test "info.supervisor extracts the supervisor version" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.supervisor
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.06.0" ]
}

@test "info.supervisor propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.supervisor || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.homeassistant
# ---------------------------------------------------------------------------

@test "info.homeassistant extracts the Home Assistant version" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.homeassistant
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.6.1" ]
}

@test "info.homeassistant propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.homeassistant || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.hassos
# ---------------------------------------------------------------------------

@test "info.hassos extracts the hassos version" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.hassos
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.3" ]
}

@test "info.hassos propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.hassos || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.hostname
# ---------------------------------------------------------------------------

@test "info.hostname extracts the hostname" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.hostname
    [ "${status}" -eq 0 ]
    [ "${output}" = "homeassistant" ]
}

@test "info.hostname propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.hostname || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.machine
# ---------------------------------------------------------------------------

@test "info.machine extracts the machine type" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.machine
    [ "${status}" -eq 0 ]
    [ "${output}" = "generic-x86-64" ]
}

@test "info.machine propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.machine || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.arch
# ---------------------------------------------------------------------------

@test "info.arch extracts the architecture" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.arch
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
}

@test "info.arch propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.arch || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.channel
# ---------------------------------------------------------------------------

@test "info.channel extracts the channel" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.channel
    [ "${status}" -eq 0 ]
    [ "${output}" = "stable" ]
}

@test "info.channel propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.channel || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.supported_arch
# ---------------------------------------------------------------------------

@test "info.supported_arch returns one architecture per line" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.supported_arch
    [ "${status}" -eq 0 ]
    # The fixture array is fixed, so assert the exact newline-separated output.
    [ "${output}" = "aarch64
amd64
armhf
armv7
i386" ]
}

@test "info.supported_arch propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.supported_arch || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.logging
# ---------------------------------------------------------------------------

@test "info.logging extracts the logging level" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.logging
    [ "${status}" -eq 0 ]
    [ "${output}" = "info" ]
}

@test "info.logging propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.logging || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.timezone
# ---------------------------------------------------------------------------

@test "info.timezone extracts the timezone" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.timezone
    [ "${status}" -eq 0 ]
    [ "${output}" = "Europe/Amsterdam" ]
}

@test "info.timezone propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.timezone || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.supported
# ---------------------------------------------------------------------------

@test "info.supported extracts the supported flag" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.supported
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "info.supported propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.supported || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.docker
# ---------------------------------------------------------------------------

@test "info.docker extracts the Docker version" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.docker
    [ "${status}" -eq 0 ]
    [ "${output}" = "24.0.7" ]
}

@test "info.docker propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.docker || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.operating_system
# ---------------------------------------------------------------------------

@test "info.operating_system extracts the OS name" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.operating_system
    [ "${status}" -eq 0 ]
    [ "${output}" = "Home Assistant OS" ]
}

@test "info.operating_system propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.operating_system || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::info.state
# ---------------------------------------------------------------------------

@test "info.state extracts the Supervisor state" {
    bashio::api.supervisor() { printf '%s' "${INFO_JSON}"; }
    run bashio::info.state
    [ "${status}" -eq 0 ]
    [ "${output}" = "running" ]
}

@test "info.state propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::info.state || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Caching isolation: each filtered key gets its own cache slot
# ---------------------------------------------------------------------------

@test "info getters cache each field independently" {
    local call_file="${BATS_TEST_TMPDIR}/calls2"
    printf '0' >"${call_file}"
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        printf '%s' "${INFO_JSON}"
    }
    # Call the field getter so its filtered value is cached under its own key
    # ('supervisor.info.arch'), alongside the base 'info' blob cache.
    [ "$(bashio::info.arch)" = "amd64" ]
    [ "$(cat "${call_file}")" -eq 1 ]

    # Flush ONLY the base 'info' blob cache key, leaving the per-field key intact.
    bashio::cache.flush 'info'

    # Re-call the same getter with a now-failing api stub. If the per-field value
    # were not cached on its own key, this would fall through to the API and fail.
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        return 1
    }
    [ "$(bashio::info.arch)" = "amd64" ]
    # No additional API call was made; the value came from the per-field cache.
    [ "$(cat "${call_file}")" -eq 1 ]
}
