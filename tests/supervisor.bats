#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/supervisor.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::supervisor` fetcher, jq filtering, and caching run. The cache is
# pointed at a per-test temporary directory so tests stay isolated.
#
# Conventions used throughout:
#   - The api stub records its full argument string ("$*") to a file so the
#     exact call (method, resource and any JSON options/filter) can be asserted.
#   - Getters route through the `bashio::supervisor` / `bashio::supervisor.stats`
#     fetchers, which cache their results in __BASHIO_CACHE_DIR.
#   - Booleans posted by setters use the "^" raw-JSON prefix in var.json, so
#     they appear unquoted (e.g. {"debug":true}); plain values are quoted.
#   - The fetchers print with `printf "%s"` (no trailing newline); bats `run`
#     strips trailing newlines, so ${output} compares cleanly.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ==============================================================================
# bashio::supervisor.ping
# ==============================================================================

@test "supervisor.ping calls the ping endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.ping
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /supervisor/ping" ]
}

@test "supervisor.ping propagates a failing API call" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.ping || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.update
# ==============================================================================

@test "supervisor.update posts the version as JSON options when given" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.update "2024.1.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/update {"version":"2024.1.0"}' ]
}

@test "supervisor.update posts without a body when no version is given" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /supervisor/update" ]
}

@test "supervisor.update reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.update "2024.1.0" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "supervisor.update without version reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.update || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.reload
# ==============================================================================

@test "supervisor.reload calls the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /supervisor/reload" ]
}

@test "supervisor.reload reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.restart
# ==============================================================================

@test "supervisor.restart calls the restart endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.restart
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /supervisor/restart" ]
}

@test "supervisor.restart reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.restart || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.repair
# ==============================================================================

@test "supervisor.repair calls the repair endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.repair
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /supervisor/repair" ]
}

@test "supervisor.repair reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.repair || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.logs / bashio::supervisor.logs_latest
# ==============================================================================

@test "supervisor.logs fetches the logs in raw mode" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.logs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /supervisor/logs true" ]
}

@test "supervisor.logs_latest fetches the latest logs" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.logs_latest
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /supervisor/logs/latest true" ]
}

# ==============================================================================
# bashio::supervisor (info fetcher)
# ==============================================================================

@test "supervisor returns the full info object when no filter is given" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0","arch":"amd64"}'; }
    run bashio::supervisor
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"version":"2024.1.0","arch":"amd64"}' ]
}

@test "supervisor fetches info from the API with the expected endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"2024.1.0"}'
    }
    run bashio::supervisor
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /supervisor/info false" ]
}

@test "supervisor applies a jq filter when provided" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0","arch":"amd64"}'; }
    run bashio::supervisor 'supervisor.info.arch' '.arch'
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
}

@test "supervisor reports failure when the info API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "supervisor serves a cached result without calling the API" {
    bashio::cache.set 'supervisor.info' '{"version":"cached"}'
    bashio::api.supervisor() {
        echo "called" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"fresh"}'
    }
    run bashio::supervisor
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"version":"cached"}' ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "supervisor caches the filtered result under the given cache key" {
    bashio::api.supervisor() { printf '%s' '{"arch":"amd64"}'; }
    run bashio::supervisor 'my.key' '.arch'
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
    [ "$(bashio::cache.get 'my.key')" = "amd64" ]
}

# ==============================================================================
# Info getters (route through bashio::supervisor)
# ==============================================================================

@test "supervisor.version extracts the version from the info response" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0","arch":"amd64"}'; }
    run bashio::supervisor.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "supervisor.version_latest extracts the latest version" {
    bashio::api.supervisor() { printf '%s' '{"version_latest":"2024.2.0"}'; }
    run bashio::supervisor.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.2.0" ]
}

@test "supervisor.update_available returns the update flag" {
    bashio::api.supervisor() { printf '%s' '{"update_available":true}'; }
    run bashio::supervisor.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "supervisor.update_available defaults to false when absent" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::supervisor.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "supervisor.arch extracts the architecture from the info response" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0","arch":"amd64"}'; }
    run bashio::supervisor.arch
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
}

@test "supervisor.supported returns the supported flag" {
    bashio::api.supervisor() { printf '%s' '{"supported":true}'; }
    run bashio::supervisor.supported
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "supervisor.healthy returns the healthy flag" {
    bashio::api.supervisor() { printf '%s' '{"healthy":false}'; }
    run bashio::supervisor.healthy
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "supervisor.ip_address returns the ip address" {
    bashio::api.supervisor() { printf '%s' '{"ip_address":"172.30.32.2"}'; }
    run bashio::supervisor.ip_address
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.2" ]
}

# ==============================================================================
# bashio::supervisor.channel (get vs set)
# ==============================================================================

@test "supervisor.channel sends the channel as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.channel "beta"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"channel":"beta"}' ]
}

@test "supervisor.channel without argument reads the current channel" {
    bashio::api.supervisor() { printf '%s' '{"channel":"stable"}'; }
    run bashio::supervisor.channel
    [ "${status}" -eq 0 ]
    [ "${output}" = "stable" ]
}

@test "supervisor.channel defaults to false when channel is absent" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::supervisor.channel
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "supervisor.channel reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.channel "beta" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.timezone (get vs set)
# ==============================================================================

@test "supervisor.timezone sets the timezone as JSON options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.timezone "Europe/Amsterdam"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"timezone":"Europe/Amsterdam"}' ]
}

@test "supervisor.timezone without argument reads the current timezone" {
    bashio::api.supervisor() { printf '%s' '{"timezone":"Europe/Amsterdam"}'; }
    run bashio::supervisor.timezone
    [ "${status}" -eq 0 ]
    [ "${output}" = "Europe/Amsterdam" ]
}

@test "supervisor.timezone reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.timezone "Europe/Amsterdam" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.country (get vs set)
# ==============================================================================

@test "supervisor.country sets the country as JSON options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.country "NL"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"country":"NL"}' ]
}

@test "supervisor.country without argument reads the current country" {
    bashio::api.supervisor() { printf '%s' '{"country":"NL"}'; }
    run bashio::supervisor.country
    [ "${status}" -eq 0 ]
    [ "${output}" = "NL" ]
}

@test "supervisor.country reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.country "NL" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.logging (get vs set)
# ==============================================================================

@test "supervisor.logging sets the logging level as JSON options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.logging "debug"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"logging":"debug"}' ]
}

@test "supervisor.logging without argument reads the current logging level" {
    bashio::api.supervisor() { printf '%s' '{"logging":"info"}'; }
    run bashio::supervisor.logging
    [ "${status}" -eq 0 ]
    [ "${output}" = "info" ]
}

@test "supervisor.logging reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.logging "debug" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.debug (get vs set, both boolean branches)
# ==============================================================================

@test "supervisor.debug enables debug as a raw-boolean JSON option" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.debug "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"debug":true}' ]
}

@test "supervisor.debug disables debug for any non-true value" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.debug "false"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"debug":false}' ]
}

@test "supervisor.debug without argument reads the current debug flag" {
    bashio::api.supervisor() { printf '%s' '{"debug":true}'; }
    run bashio::supervisor.debug
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "supervisor.debug defaults to false when absent" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::supervisor.debug
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "supervisor.debug reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.debug "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.debug_block (get vs set, both boolean branches)
# ==============================================================================

@test "supervisor.debug_block enables debug block as a raw-boolean JSON option" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.debug_block "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"debug_block":true}' ]
}

@test "supervisor.debug_block disables debug block for any non-true value" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.debug_block "false"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"debug_block":false}' ]
}

@test "supervisor.debug_block without argument reads the current flag" {
    bashio::api.supervisor() { printf '%s' '{"debug_block":true}'; }
    run bashio::supervisor.debug_block
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "supervisor.debug_block defaults to false when absent" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::supervisor.debug_block
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "supervisor.debug_block reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.debug_block "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.diagnostics (get vs set, both boolean branches)
# ==============================================================================

@test "supervisor.diagnostics enables diagnostics as JSON options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.diagnostics "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"diagnostics":true}' ]
}

@test "supervisor.diagnostics disables diagnostics for any non-true value" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.diagnostics "false"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"diagnostics":false}' ]
}

@test "supervisor.diagnostics without argument reads the current flag" {
    bashio::api.supervisor() { printf '%s' '{"diagnostics":true}'; }
    run bashio::supervisor.diagnostics
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "supervisor.diagnostics reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.diagnostics "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.auto_update (get vs set, both boolean branches)
# ==============================================================================

@test "supervisor.auto_update enables auto update as a raw-boolean JSON option" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.auto_update "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"auto_update":true}' ]
}

@test "supervisor.auto_update disables auto update for any non-true value" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.auto_update "false"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"auto_update":false}' ]
}

@test "supervisor.auto_update without argument reads the current flag" {
    bashio::api.supervisor() { printf '%s' '{"auto_update":false}'; }
    run bashio::supervisor.auto_update
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "supervisor.auto_update reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.auto_update "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.detect_blocking_io (get vs set)
#
# Unlike the boolean setters, this one posts the value verbatim (no "^" prefix),
# so values like "on"/"off"/"on-at-startup" are sent as JSON strings.
# ==============================================================================

@test "supervisor.detect_blocking_io sets the value as a JSON string option" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.detect_blocking_io "on"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"detect_blocking_io":"on"}' ]
}

@test "supervisor.detect_blocking_io accepts the on-at-startup value" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.detect_blocking_io "on-at-startup"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"detect_blocking_io":"on-at-startup"}' ]
}

@test "supervisor.detect_blocking_io without argument reads the current value" {
    bashio::api.supervisor() { printf '%s' '{"detect_blocking_io":"off"}'; }
    run bashio::supervisor.detect_blocking_io
    [ "${status}" -eq 0 ]
    [ "${output}" = "off" ]
}

@test "supervisor.detect_blocking_io reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.detect_blocking_io "on" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ==============================================================================
# bashio::supervisor.addons / bashio::supervisor.addons_repositories
#
# These delegate to addons.installed and repositories respectively (kept for
# backward compatibility). We stub the API boundary and assert the delegated
# behaviour end to end.
# ==============================================================================

@test "supervisor.addons lists the slugs of installed apps" {
    bashio::api.supervisor() {
        printf '%s' '{"addons":[{"slug":"core_ssh","installed":true},{"slug":"core_samba","installed":false},{"slug":"local_test","installed":true}]}'
    }
    run bashio::supervisor.addons
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "core_ssh" ]
    [ "${lines[1]}" = "local_test" ]
}

@test "supervisor.addons_repositories lists name/slug objects per repository" {
    bashio::api.supervisor() {
        printf '%s' '[{"name":"Core","slug":"core","url":"x"},{"name":"Local","slug":"local"}]'
    }
    run bashio::supervisor.addons_repositories
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = '{"name":"Core","slug":"core"}' ]
    [ "${lines[1]}" = '{"name":"Local","slug":"local"}' ]
}

# ==============================================================================
# bashio::supervisor.stats (stats fetcher)
# ==============================================================================

@test "supervisor.stats returns the full stats object when no filter is given" {
    bashio::api.supervisor() { printf '%s' '{"cpu_percent":1.5,"memory_usage":100}'; }
    run bashio::supervisor.stats
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"cpu_percent":1.5,"memory_usage":100}' ]
}

@test "supervisor.stats fetches stats from the API with the expected endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::supervisor.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /supervisor/stats false" ]
}

@test "supervisor.stats applies a jq filter when provided" {
    bashio::api.supervisor() { printf '%s' '{"cpu_percent":2.5}'; }
    run bashio::supervisor.stats 'supervisor.stats.cpu_percent' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.5" ]
}

@test "supervisor.stats reports failure when the stats API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::supervisor.stats || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "supervisor.stats serves a cached result without calling the API" {
    bashio::cache.set 'supervisor.stats' '{"cpu_percent":9.9}'
    bashio::api.supervisor() {
        echo "called" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":0}'
    }
    run bashio::supervisor.stats
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"cpu_percent":9.9}' ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ==============================================================================
# Stats accessors (route through bashio::supervisor.stats)
# ==============================================================================

@test "supervisor.cpu_percent extracts cpu usage" {
    bashio::api.supervisor() { printf '%s' '{"cpu_percent":12.3}'; }
    run bashio::supervisor.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.3" ]
}

@test "supervisor.memory_usage extracts memory usage" {
    bashio::api.supervisor() { printf '%s' '{"memory_usage":204800}'; }
    run bashio::supervisor.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "204800" ]
}

@test "supervisor.memory_limit extracts the memory limit" {
    bashio::api.supervisor() { printf '%s' '{"memory_limit":1048576}'; }
    run bashio::supervisor.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "1048576" ]
}

@test "supervisor.memory_percent extracts the memory percentage" {
    bashio::api.supervisor() { printf '%s' '{"memory_percent":42.0}'; }
    run bashio::supervisor.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "42.0" ]
}

@test "supervisor.network_tx extracts outgoing network usage" {
    bashio::api.supervisor() { printf '%s' '{"network_tx":555}'; }
    run bashio::supervisor.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "555" ]
}

@test "supervisor.network_rx extracts incoming network usage" {
    bashio::api.supervisor() { printf '%s' '{"network_rx":666}'; }
    run bashio::supervisor.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "666" ]
}

@test "supervisor.blk_read extracts disk read usage" {
    bashio::api.supervisor() { printf '%s' '{"blk_read":777}'; }
    run bashio::supervisor.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "777" ]
}

@test "supervisor.blk_write extracts disk write usage" {
    bashio::api.supervisor() { printf '%s' '{"blk_write":888}'; }
    run bashio::supervisor.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "888" ]
}
