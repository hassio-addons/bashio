#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/resolution.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::resolution` fetcher, jq filtering, and caching run. The cache is
# pointed at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::resolution (info fetcher)
# ------------------------------------------------------------------------------

@test "resolution fetches the info endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"unsupported":[],"unhealthy":[]}'
    }
    run bashio::resolution
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /resolution/info false" ]
    [ "${output}" = '{"unsupported":[],"unhealthy":[]}' ]
}

@test "resolution applies a jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"unsupported":["apparmor"]}'
    }
    run bashio::resolution 'resolution.info.custom' '.unsupported[0]'
    [ "${status}" -eq 0 ]
    [ "${output}" = "apparmor" ]
}

@test "resolution reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::resolution
    [ "${status}" -ne 0 ]
}

@test "resolution serves a previously cached value without calling the API" {
    bashio::cache.set 'resolution.info.cached' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::resolution 'resolution.info.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.unsupported
# ------------------------------------------------------------------------------

@test "resolution.unsupported lists the unsupported reasons" {
    bashio::api.supervisor() {
        printf '%s' '{"unsupported":["apparmor","docker_version"]}'
    }
    run bashio::resolution.unsupported
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "apparmor" ]
    [ "${lines[1]}" = "docker_version" ]
}

@test "resolution.unsupported propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::resolution.unsupported
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.unhealthy
# ------------------------------------------------------------------------------

@test "resolution.unhealthy lists the unhealthy reasons" {
    bashio::api.supervisor() {
        printf '%s' '{"unhealthy":["docker","supervisor"]}'
    }
    run bashio::resolution.unhealthy
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "docker" ]
    [ "${lines[1]}" = "supervisor" ]
}

@test "resolution.unhealthy propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::resolution.unhealthy
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.issues
# ------------------------------------------------------------------------------

@test "resolution.issues lists the current issues" {
    bashio::api.supervisor() {
        printf '%s' '{"issues":[{"uuid":"abc","type":"free_space"}]}'
    }
    run bashio::resolution.issues
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"uuid":"abc","type":"free_space"}' ]
}

@test "resolution.issues propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::resolution.issues
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.suggestions
# ------------------------------------------------------------------------------

@test "resolution.suggestions lists the current suggestions" {
    bashio::api.supervisor() {
        printf '%s' '{"suggestions":[{"uuid":"def","type":"clear_full_backup"}]}'
    }
    run bashio::resolution.suggestions
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"uuid":"def","type":"clear_full_backup"}' ]
}

@test "resolution.suggestions propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::resolution.suggestions
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.checks
# ------------------------------------------------------------------------------

@test "resolution.checks lists the available checks" {
    bashio::api.supervisor() {
        printf '%s' '{"checks":[{"enabled":true,"slug":"free_space"}]}'
    }
    run bashio::resolution.checks
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"enabled":true,"slug":"free_space"}' ]
}

@test "resolution.checks propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::resolution.checks
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.suggestion.apply
# ------------------------------------------------------------------------------

@test "resolution.suggestion.apply posts to the suggestion endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::resolution.suggestion.apply "abcd-1234"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /resolution/suggestion/abcd-1234" ]
}

@test "resolution.suggestion.apply propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::resolution.suggestion.apply "abcd-1234" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.suggestion.dismiss
# ------------------------------------------------------------------------------

@test "resolution.suggestion.dismiss deletes the suggestion endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::resolution.suggestion.dismiss "abcd-1234"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /resolution/suggestion/abcd-1234" ]
}

@test "resolution.suggestion.dismiss propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::resolution.suggestion.dismiss "abcd-1234" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.issue.dismiss
# ------------------------------------------------------------------------------

@test "resolution.issue.dismiss deletes the issue endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::resolution.issue.dismiss "ef01-5678"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /resolution/issue/ef01-5678" ]
}

@test "resolution.issue.dismiss propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::resolution.issue.dismiss "ef01-5678" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.check
# ------------------------------------------------------------------------------

@test "resolution.check posts to the check run endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::resolution.check "free_space"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /resolution/check/free_space/run" ]
}

@test "resolution.check propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::resolution.check "free_space" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::resolution.healthcheck
# ------------------------------------------------------------------------------

@test "resolution.healthcheck posts to the healthcheck endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::resolution.healthcheck
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /resolution/healthcheck" ]
}

@test "resolution.healthcheck propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::resolution.healthcheck || rc=$?
    [ "${rc}" -ne 0 ]
}
