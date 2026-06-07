#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/host.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::host` fetcher, jq filtering, and caching run. The cache is pointed at
# a per-test temporary directory so tests stay isolated. The action helpers
# (reload/shutdown/reboot/logs) are checked for correct method/resource/filter
# forwarding, the getters for the value they return, and every setter and action
# for error propagation.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# Actions: reload / shutdown / reboot / logs.
# ------------------------------------------------------------------------------

@test "host.reload posts to the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /host/reload" ]
}

@test "host.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::host.reload
    [ "${status}" -ne 0 ]
}

@test "host.shutdown posts to the shutdown endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host.shutdown
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /host/shutdown" ]
}

@test "host.shutdown propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::host.shutdown
    [ "${status}" -ne 0 ]
}

@test "host.reboot posts to the reboot endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host.reboot
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /host/reboot" ]
}

@test "host.reboot propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::host.reboot
    [ "${status}" -ne 0 ]
}

@test "host.logs fetches the host logs as raw output" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host.logs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /host/logs true" ]
}

@test "host.logs propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::host.logs
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Core fetcher: bashio::host.
# ------------------------------------------------------------------------------

@test "host fetches info from the API with the correct method and resource" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"hostname":"homeassistant"}'
    }
    run bashio::host
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /host/info false" ]
    [ "${output}" = '{"hostname":"homeassistant"}' ]
}

@test "host applies the supplied jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"hostname":"homeassistant","chassis":"vm"}'
    }
    run bashio::host 'host.info.chassis' '.chassis'
    [ "${status}" -eq 0 ]
    [ "${output}" = "vm" ]
}

@test "host returns a cached value without calling the API" {
    bashio::cache.set 'my.key' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host 'my.key'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "host reuses cached host.info instead of refetching" {
    bashio::cache.set 'host.info' '{"hostname":"cached-host"}'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host 'host.info.hostname' '.hostname'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-host" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "host caches the filtered response under the cache key" {
    bashio::api.supervisor() {
        printf '%s' '{"hostname":"homeassistant"}'
    }
    bashio::host 'host.info.hostname' '.hostname' >/dev/null
    run bashio::cache.get 'host.info.hostname'
    [ "${status}" -eq 0 ]
    [ "${output}" = "homeassistant" ]
}

@test "host fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::host
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::host.services
# ------------------------------------------------------------------------------

@test "host.services calls GET /host/services" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"services":[{"name":"sshd.service","state":"active"}]}'
    }
    run bashio::host.services
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /host/services false" ]
    [ "${output}" = '{"services":[{"name":"sshd.service","state":"active"}]}' ]
}

@test "host.services applies an optional jq filter" {
    bashio::api.supervisor() {
        printf '%s' '{"services":[{"name":"sshd.service","state":"active"}]}'
    }
    run bashio::host.services 'host.services.first' '.services[0].name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "sshd.service" ]
}

@test "host.services propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::host.services || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "host.services propagates a jq filter failure" {
    bashio::api.supervisor() { printf '%s' '{"services":[]}'; }
    rc=0
    bashio::host.services 'host.services.bad' 'INVALID_FILTER_!!!' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "host.services with the base key and a filter does not corrupt the base blob" {
    bashio::api.supervisor() {
        printf '%s' '{"services":[{"name":"sshd.service"}]}'
    }
    run bashio::host.services 'host.services' '.services[0].name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "sshd.service" ]
    run bashio::cache.get 'host.services'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.services[0].name')" = "sshd.service" ]
}

# ------------------------------------------------------------------------------
# bashio::host.disk_usage
# ------------------------------------------------------------------------------

@test "host.disk_usage calls GET /host/disks/default/usage" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"total":100,"used":40,"free":60}'
    }
    run bashio::host.disk_usage
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /host/disks/default/usage false" ]
    [ "${output}" = '{"total":100,"used":40,"free":60}' ]
}

@test "host.disk_usage applies an optional jq filter" {
    bashio::api.supervisor() { printf '%s' '{"total":100,"used":40,"free":60}'; }
    run bashio::host.disk_usage 'host.disk_usage.free' '.free'
    [ "${status}" -eq 0 ]
    [ "${output}" = "60" ]
}

@test "host.disk_usage propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::host.disk_usage || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "host.disk_usage propagates a jq filter failure" {
    bashio::api.supervisor() { printf '%s' '{"total":100,"used":40,"free":60}'; }
    rc=0
    bashio::host.disk_usage 'host.disk_usage.bad' 'INVALID_FILTER_!!!' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "host.disk_usage with the base key and a filter does not corrupt the base blob" {
    bashio::api.supervisor() { printf '%s' '{"total":100,"used":40,"free":60}'; }
    run bashio::host.disk_usage 'host.disk_usage' '.free'
    [ "${status}" -eq 0 ]
    [ "${output}" = "60" ]
    run bashio::cache.get 'host.disk_usage'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.free')" = "60" ]
}

# ------------------------------------------------------------------------------
# hostname getter/setter.
# ------------------------------------------------------------------------------

@test "host.hostname returns the hostname when called without arguments" {
    bashio::api.supervisor() {
        printf '%s' '{"hostname":"homeassistant"}'
    }
    run bashio::host.hostname
    [ "${status}" -eq 0 ]
    [ "${output}" = "homeassistant" ]
}

@test "host.hostname sets the hostname as JSON options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::host.hostname "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /host/options {"hostname":"example"}' ]
}

@test "host.hostname propagates an API failure when setting" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::host.hostname "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Simple getters: each forwards a fixed cache key and jq filter.
# ------------------------------------------------------------------------------

@test "host.features returns the features array" {
    bashio::api.supervisor() {
        printf '%s' '{"features":["reboot","shutdown"]}'
    }
    run bashio::host.features
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "reboot" ]
    [ "${lines[1]}" = "shutdown" ]
}

@test "host.operating_system returns the operating system" {
    bashio::api.supervisor() {
        printf '%s' '{"operating_system":"Home Assistant OS 12.0"}'
    }
    run bashio::host.operating_system
    [ "${status}" -eq 0 ]
    [ "${output}" = "Home Assistant OS 12.0" ]
}

@test "host.kernel returns the kernel" {
    bashio::api.supervisor() {
        printf '%s' '{"kernel":"6.1.0"}'
    }
    run bashio::host.kernel
    [ "${status}" -eq 0 ]
    [ "${output}" = "6.1.0" ]
}

@test "host.chassis returns the chassis" {
    bashio::api.supervisor() {
        printf '%s' '{"chassis":"vm"}'
    }
    run bashio::host.chassis
    [ "${status}" -eq 0 ]
    [ "${output}" = "vm" ]
}

@test "host.deployment returns the deployment channel" {
    bashio::api.supervisor() {
        printf '%s' '{"deployment":"production"}'
    }
    run bashio::host.deployment
    [ "${status}" -eq 0 ]
    [ "${output}" = "production" ]
}

@test "host.cpe returns the cpe" {
    bashio::api.supervisor() {
        printf '%s' '{"cpe":"cpe:2.3:o:home-assistant:haos:12.0"}'
    }
    run bashio::host.cpe
    [ "${status}" -eq 0 ]
    [ "${output}" = "cpe:2.3:o:home-assistant:haos:12.0" ]
}

@test "host.disk_free returns the free disk space" {
    bashio::api.supervisor() {
        printf '%s' '{"disk_free":12.3}'
    }
    run bashio::host.disk_free
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.3" ]
}

@test "host.disk_total returns the total disk space" {
    bashio::api.supervisor() {
        printf '%s' '{"disk_total":32.5}'
    }
    run bashio::host.disk_total
    [ "${status}" -eq 0 ]
    [ "${output}" = "32.5" ]
}

@test "host.disk_used returns the used disk space" {
    bashio::api.supervisor() {
        printf '%s' '{"disk_used":19.7}'
    }
    run bashio::host.disk_used
    [ "${status}" -eq 0 ]
    [ "${output}" = "19.7" ]
}

@test "host.operating_system propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::host.operating_system
    [ "${status}" -ne 0 ]
}
