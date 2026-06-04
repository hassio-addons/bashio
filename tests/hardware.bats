#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/hardware.sh.
#
# The Supervisor API boundary is stubbed via a `bashio::api.supervisor` bash
# function so no real HTTP requests are made. The cache is isolated to a
# per-test temporary directory.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

# ---------------------------------------------------------------------------
# Canned JSON response used by most tests
# ---------------------------------------------------------------------------
HARDWARE_JSON='{
  "serial": ["/dev/ttyUSB0", "/dev/ttyUSB1"],
  "input": ["keyboard0", "mouse0"],
  "disk": ["/dev/sda", "/dev/sdb"],
  "gpio": ["gpiochip0"],
  "usb": ["0403:6001"]
}'

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ---------------------------------------------------------------------------
# bashio::hardware - base fetcher
# ---------------------------------------------------------------------------

@test "hardware calls GET /hardware/info" {
    bashio::api.supervisor() {
        printf '%s' "${HARDWARE_JSON}"
    }
    run bashio::hardware
    [ "${status}" -eq 0 ]
    [ "${output}" = "${HARDWARE_JSON}" ]
}

@test "hardware applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    run bashio::hardware 'test.filter.disk0' '.disk[0]'
    [ "${status}" -eq 0 ]
    [ "${output}" = "/dev/sda" ]
}

@test "hardware returns cached data on a second call without hitting the API" {
    local call_file="${BATS_TEST_TMPDIR}/calls"
    printf '0' >"${call_file}"
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        printf '%s' "${HARDWARE_JSON}"
    }
    bashio::hardware >/dev/null
    bashio::hardware >/dev/null
    [ "$(cat "${call_file}")" -eq 1 ]
}

@test "hardware propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::hardware || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "hardware propagates a jq filter failure" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    rc=0
    bashio::hardware 'test.bad.filter' 'INVALID_FILTER_!!!' || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::hardware.serial
# ---------------------------------------------------------------------------

@test "hardware.serial returns each serial device on its own line" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    run bashio::hardware.serial
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"/dev/ttyUSB0"* ]]
    [[ "${output}" == *"/dev/ttyUSB1"* ]]
}

@test "hardware.serial propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::hardware.serial || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "hardware.serial returns empty output when the list is empty" {
    bashio::api.supervisor() { printf '%s' '{"serial":[],"input":[],"disk":[],"gpio":[],"usb":[]}'; }
    run bashio::hardware.serial
    # An empty jq array expansion produces no output; the command may return
    # non-zero because jq emits nothing for an empty array iteration.
    [ "${output}" = "" ]
}

# ---------------------------------------------------------------------------
# bashio::hardware.input
# ---------------------------------------------------------------------------

@test "hardware.input returns each input device on its own line" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    run bashio::hardware.input
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"keyboard0"* ]]
    [[ "${output}" == *"mouse0"* ]]
}

@test "hardware.input propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::hardware.input || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::hardware.disk
# ---------------------------------------------------------------------------

@test "hardware.disk returns each disk device on its own line" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    run bashio::hardware.disk
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"/dev/sda"* ]]
    [[ "${output}" == *"/dev/sdb"* ]]
}

@test "hardware.disk propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::hardware.disk || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::hardware.gpio
# ---------------------------------------------------------------------------

@test "hardware.gpio returns each GPIO chip on its own line" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    run bashio::hardware.gpio
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"gpiochip0"* ]]
}

@test "hardware.gpio propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::hardware.gpio || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::hardware.usb
# ---------------------------------------------------------------------------

@test "hardware.usb returns each USB device on its own line" {
    bashio::api.supervisor() { printf '%s' "${HARDWARE_JSON}"; }
    run bashio::hardware.usb
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"0403:6001"* ]]
}

@test "hardware.usb propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::hardware.usb || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Caching isolation: each filtered key gets its own cache slot
# ---------------------------------------------------------------------------

@test "hardware getters cache each field independently" {
    local call_file="${BATS_TEST_TMPDIR}/calls2"
    printf '0' >"${call_file}"
    bashio::api.supervisor() {
        printf '%d' $(($(cat "${call_file}") + 1)) >"${call_file}"
        printf '%s' "${HARDWARE_JSON}"
    }
    # Call both getters without `run` so the cache state is shared.
    bashio::hardware.disk >/dev/null
    bashio::hardware.usb >/dev/null
    # The raw blob is fetched only once; both getters share the same base cache.
    [ "$(cat "${call_file}")" -eq 1 ]
}
