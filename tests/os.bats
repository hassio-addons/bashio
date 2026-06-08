#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/os.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::os` fetcher, jq filtering, and caching run. The cache is pointed at a
# per-test temporary directory so tests stay isolated. The update action and the
# config_sync action are checked for correct method/resource forwarding, the
# getters for the value they return, and the actions for error propagation.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# os.update: posts (optionally) a version and flushes the cache.
# ------------------------------------------------------------------------------

@test "os.update posts to the update endpoint without a version" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /os/update" ]
}

@test "os.update posts the version as JSON options when supplied" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.update "12.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /os/update {"version":"12.0"}' ]
}

@test "os.update flushes the cache after a successful update" {
    bashio::cache.set 'os.info' '{"version":"11.0"}'
    bashio::api.supervisor() { return 0; }
    run bashio::os.update "12.0"
    [ "${status}" -eq 0 ]
    run bashio::cache.exists 'os.info'
    [ "${status}" -ne 0 ]
}

@test "os.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.update propagates an API failure when a version is supplied" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.update "12.0" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# os.config_sync action.
# ------------------------------------------------------------------------------

@test "os.config_sync posts to the config sync endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.config_sync
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /os/config/sync" ]
}

@test "os.config_sync propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::os.config_sync
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Core fetcher: bashio::os.
# ------------------------------------------------------------------------------

@test "os fetches info from the API with the correct method and resource" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"12.0"}'
    }
    run bashio::os
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /os/info false" ]
    [ "${output}" = '{"version":"12.0"}' ]
}

@test "os applies the supplied jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"12.0","board":"rpi4"}'
    }
    run bashio::os 'os.info.board' '.board'
    [ "${status}" -eq 0 ]
    [ "${output}" = "rpi4" ]
}

@test "os returns a cached value without calling the API" {
    bashio::cache.set 'my.key' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os 'my.key'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "os reuses cached os.info instead of refetching" {
    bashio::cache.set 'os.info' '{"version":"cached-version"}'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os 'os.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-version" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "os caches the filtered response under the cache key" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"12.0"}'
    }
    bashio::os 'os.info.version' '.version' >/dev/null
    run bashio::cache.get 'os.info.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.0" ]
}

@test "os fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::os
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Simple getters: each forwards a fixed cache key and jq filter.
# ------------------------------------------------------------------------------

@test "os.version returns the version" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"12.0"}'
    }
    run bashio::os.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.0" ]
}

@test "os.version_latest returns the latest version" {
    bashio::api.supervisor() {
        printf '%s' '{"version_latest":"12.1"}'
    }
    run bashio::os.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.1" ]
}

@test "os.update_available returns true when an update is available" {
    bashio::api.supervisor() {
        printf '%s' '{"update_available":true}'
    }
    run bashio::os.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "os.update_available defaults to false when the field is absent" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"12.0"}'
    }
    run bashio::os.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "os.board returns the board" {
    bashio::api.supervisor() {
        printf '%s' '{"board":"rpi4"}'
    }
    run bashio::os.board
    [ "${status}" -eq 0 ]
    [ "${output}" = "rpi4" ]
}

@test "os.boot returns the active boot slot" {
    bashio::api.supervisor() {
        printf '%s' '{"boot":"A"}'
    }
    run bashio::os.boot
    [ "${status}" -eq 0 ]
    [ "${output}" = "A" ]
}

@test "os.version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::os.version
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::os.swap (getter) and bashio::os.swap.options (setter)
# ------------------------------------------------------------------------------

@test "os.swap calls GET /os/config/swap" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"swap_size":"1G","swappiness":60}'
    }
    run bashio::os.swap
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /os/config/swap false" ]
    [ "${output}" = '{"swap_size":"1G","swappiness":60}' ]
}

@test "os.swap applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' '{"swap_size":"1G","swappiness":60}'; }
    run bashio::os.swap 'os.swap.swappiness' '.swappiness'
    [ "${status}" -eq 0 ]
    [ "${output}" = "60" ]
}

@test "os.swap propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.swap || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.swap with the base key and a filter does not corrupt the base blob" {
    bashio::api.supervisor() { printf '%s' '{"swap_size":"1G","swappiness":60}'; }
    run bashio::os.swap 'os.swap' '.swappiness'
    [ "${status}" -eq 0 ]
    [ "${output}" = "60" ]
    run bashio::cache.get 'os.swap'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.swap_size')" = "1G" ]
}

@test "os.swap.options posts the given JSON to the swap endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.swap.options '{"swappiness":80}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /os/config/swap {"swappiness":80}' ]
}

@test "os.swap.options propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.swap.options '{"swappiness":80}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.swap.options does not log the options payload" {
    logged=""
    bashio::log.trace() { logged+=" $*"; }
    bashio::api.supervisor() { return 0; }
    bashio::os.swap.options '{"swap_size":"SENTINEL_VALUE"}'
    [[ "${logged}" != *"SENTINEL_VALUE"* ]]
}

# ------------------------------------------------------------------------------
# bashio::os.datadisk.list / move / wipe
# ------------------------------------------------------------------------------

@test "os.datadisk.list calls GET /os/datadisk/list" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"devices":["sda"],"disks":[{"id":"sda"}]}'
    }
    run bashio::os.datadisk.list
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /os/datadisk/list false" ]
    [ "${output}" = '{"devices":["sda"],"disks":[{"id":"sda"}]}' ]
}

@test "os.datadisk.list propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.datadisk.list || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.datadisk.move posts the target device" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.datadisk.move "sda"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /os/datadisk/move {"device":"sda"}' ]
}

@test "os.datadisk.move escapes the device and cannot inject extra keys" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::os.datadisk.move 'x","y":"z'
    [ "${status}" -eq 0 ]
    run jq -e 'has("y")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "os.datadisk.move propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.datadisk.move "sda" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.datadisk.wipe posts to the wipe endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.datadisk.wipe
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /os/datadisk/wipe" ]
}

@test "os.datadisk.wipe propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.datadisk.wipe || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::os.boot_slot
# ------------------------------------------------------------------------------

@test "os.boot_slot posts the requested slot" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.boot_slot "B"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /os/boot-slot {"boot_slot":"B"}' ]
}

@test "os.boot_slot escapes the slot and cannot inject extra keys" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::os.boot_slot 'A","y":"z'
    [ "${status}" -eq 0 ]
    run jq -e 'has("y")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "os.boot_slot propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.boot_slot "B" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::os.boards.green (getter + options setter)
# ------------------------------------------------------------------------------

@test "os.boards.green calls GET /os/boards/green" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"activity_led":true,"power_led":true,"system_health_led":false}'
    }
    run bashio::os.boards.green
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /os/boards/green false" ]
    [ "${output}" = '{"activity_led":true,"power_led":true,"system_health_led":false}' ]
}

@test "os.boards.green applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' '{"activity_led":true,"power_led":false}'; }
    run bashio::os.boards.green 'os.boards.green.power' '.power_led'
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "os.boards.green propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.boards.green || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.boards.green with the base key and a filter does not corrupt the base blob" {
    bashio::api.supervisor() { printf '%s' '{"activity_led":true,"power_led":false}'; }
    run bashio::os.boards.green 'os.boards.green' '.power_led'
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
    run bashio::cache.get 'os.boards.green'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.activity_led')" = "true" ]
}

@test "os.boards.green.options posts the given JSON to the green endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.boards.green.options '{"power_led":false}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /os/boards/green {"power_led":false}' ]
}

@test "os.boards.green.options propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.boards.green.options '{"power_led":false}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.boards.green.options does not log the options payload" {
    logged=""
    bashio::log.trace() { logged+=" $*"; }
    bashio::api.supervisor() { return 0; }
    bashio::os.boards.green.options '{"power_led":"SENTINEL_VALUE"}'
    [[ "${logged}" != *"SENTINEL_VALUE"* ]]
}

# ------------------------------------------------------------------------------
# bashio::os.boards.yellow (getter + options setter)
# ------------------------------------------------------------------------------

@test "os.boards.yellow calls GET /os/boards/yellow" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"disk_led":true,"heartbeat_led":true,"power_led":true}'
    }
    run bashio::os.boards.yellow
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /os/boards/yellow false" ]
    [ "${output}" = '{"disk_led":true,"heartbeat_led":true,"power_led":true}' ]
}

@test "os.boards.yellow applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' '{"disk_led":true,"power_led":false}'; }
    run bashio::os.boards.yellow 'os.boards.yellow.disk' '.disk_led'
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "os.boards.yellow propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.boards.yellow || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.boards.yellow with the base key and a filter does not corrupt the base blob" {
    bashio::api.supervisor() { printf '%s' '{"disk_led":true,"power_led":false}'; }
    run bashio::os.boards.yellow 'os.boards.yellow' '.power_led'
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
    run bashio::cache.get 'os.boards.yellow'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.disk_led')" = "true" ]
}

@test "os.boards.yellow.options posts the given JSON to the yellow endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::os.boards.yellow.options '{"disk_led":false}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /os/boards/yellow {"disk_led":false}' ]
}

@test "os.boards.yellow.options propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::os.boards.yellow.options '{"disk_led":false}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.boards.yellow.options does not log the options payload" {
    logged=""
    bashio::log.trace() { logged+=" $*"; }
    bashio::api.supervisor() { return 0; }
    bashio::os.boards.yellow.options '{"disk_led":"SENTINEL_VALUE"}'
    [[ "${logged}" != *"SENTINEL_VALUE"* ]]
}
