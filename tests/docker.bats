#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/docker.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::docker`/`bashio::docker.registries` fetchers, jq filtering, and
# caching run. The cache is pointed at a per-test temporary directory so tests
# stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::docker (info fetcher)
# ------------------------------------------------------------------------------

@test "docker fetches the info endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"24.0.7","storage":"overlay2"}'
    }
    run bashio::docker
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /docker/info false" ]
    [ "${output}" = '{"version":"24.0.7","storage":"overlay2"}' ]
}

@test "docker applies a jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"24.0.7","storage":"overlay2"}'
    }
    run bashio::docker 'docker.info.custom' '.storage'
    [ "${status}" -eq 0 ]
    [ "${output}" = "overlay2" ]
}

@test "docker reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker
    [ "${status}" -ne 0 ]
}

@test "docker serves a previously cached value without calling the API" {
    bashio::cache.set 'docker.info.cached' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::docker 'docker.info.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::docker.version
# ------------------------------------------------------------------------------

@test "docker.version extracts the version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"24.0.7"}'
    }
    run bashio::docker.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "24.0.7" ]
}

@test "docker.version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker.version
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::docker.storage
# ------------------------------------------------------------------------------

@test "docker.storage extracts the storage driver from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"storage":"overlay2"}'
    }
    run bashio::docker.storage
    [ "${status}" -eq 0 ]
    [ "${output}" = "overlay2" ]
}

@test "docker.storage propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker.storage
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::docker.logging
# ------------------------------------------------------------------------------

@test "docker.logging extracts the logging driver from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"logging":"journald"}'
    }
    run bashio::docker.logging
    [ "${status}" -eq 0 ]
    [ "${output}" = "journald" ]
}

@test "docker.logging propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker.logging
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::docker.enable_ipv6
# ------------------------------------------------------------------------------

@test "docker.enable_ipv6 returns the boolean from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"enable_ipv6":true}'
    }
    run bashio::docker.enable_ipv6
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "docker.enable_ipv6 defaults to false when the key is missing" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"24.0.7"}'
    }
    run bashio::docker.enable_ipv6
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "docker.enable_ipv6 propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker.enable_ipv6
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::docker.mtu
# ------------------------------------------------------------------------------

@test "docker.mtu extracts the MTU from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"mtu":1500}'
    }
    run bashio::docker.mtu
    [ "${status}" -eq 0 ]
    [ "${output}" = "1500" ]
}

@test "docker.mtu propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker.mtu
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::docker.options
# ------------------------------------------------------------------------------

@test "docker.options posts the options object to the options endpoint" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::docker.options '{"enable_ipv6":true}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /docker/options {"enable_ipv6":true}' ]
}

@test "docker.options flushes the cache" {
    # Prime the cache first.
    bashio::api.supervisor() { printf '%s' '{"version":"24.0.7"}'; }
    bashio::docker >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/docker.info.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::docker.options '{"mtu":1500}'
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "docker.options propagates an API failure" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    run bashio::docker.options '{"mtu":1500}'
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /docker/options {"mtu":1500}' ]
}

# ------------------------------------------------------------------------------
# bashio::docker.registries (registries fetcher)
# ------------------------------------------------------------------------------

@test "docker.registries fetches the registries endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"registries":{"hub.docker.com":{"username":"alice"}}}'
    }
    run bashio::docker.registries
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /docker/registries false" ]
    [ "${output}" = '{"registries":{"hub.docker.com":{"username":"alice"}}}' ]
}

@test "docker.registries applies a jq filter to the response" {
    bashio::api.supervisor() {
        printf '%s' '{"registries":{"hub.docker.com":{"username":"alice"}}}'
    }
    run bashio::docker.registries 'docker.registries.names' '.registries | keys[]'
    [ "${status}" -eq 0 ]
    [ "${output}" = "hub.docker.com" ]
}

@test "docker.registries reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::docker.registries
    [ "${status}" -ne 0 ]
}

@test "docker.registries serves a previously cached value without calling the API" {
    bashio::cache.set 'docker.registries.cached' 'cached-registries'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::docker.registries 'docker.registries.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-registries" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::docker.registries.add
# ------------------------------------------------------------------------------

@test "docker.registries.add posts the exact nested credentials body" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::docker.registries.add "hub.docker.com" "alice" "s3cret"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = \
        'POST /docker/registries {"hub.docker.com":{"username":"alice","password":"s3cret"}}' ]
}

@test "docker.registries.add JSON escapes hostile credential values" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::docker.registries.add 'reg"x' 'a"b' 'c\d'
    [ "${status}" -eq 0 ]
    # The posted body must be valid JSON with the values preserved verbatim.
    body="$(cat "${BATS_TEST_TMPDIR}/body")"
    [ "$(printf '%s' "${body}" | jq -r 'keys[0]')" = 'reg"x' ]
    [ "$(printf '%s' "${body}" | jq -r '.["reg\"x"].username')" = 'a"b' ]
    [ "$(printf '%s' "${body}" | jq -r '.["reg\"x"].password')" = 'c\d' ]
}

@test "docker.registries.add flushes the cache" {
    # Prime the cache first.
    bashio::api.supervisor() {
        printf '%s' '{"registries":{"hub.docker.com":{"username":"alice"}}}'
    }
    bashio::docker.registries >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/docker.registries.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::docker.registries.add "hub.docker.com" "alice" "s3cret"
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "docker.registries.add propagates an API failure" {
    bashio::api.supervisor() {
        printf '%s' "$2" >"${BATS_TEST_TMPDIR}/endpoint"
        return 1
    }
    run bashio::docker.registries.add "hub.docker.com" "alice" "s3cret"
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/endpoint")" = "/docker/registries" ]
}

# ------------------------------------------------------------------------------
# bashio::docker.registries.remove
# ------------------------------------------------------------------------------

@test "docker.registries.remove deletes the registry by hostname" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::docker.registries.remove "hub.docker.com"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /docker/registries/hub.docker.com" ]
}

@test "docker.registries.remove flushes the cache" {
    # Prime the cache first.
    bashio::api.supervisor() {
        printf '%s' '{"registries":{"hub.docker.com":{"username":"alice"}}}'
    }
    bashio::docker.registries >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/docker.registries.cache" ]

    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call2"; }
    bashio::docker.registries.remove "hub.docker.com"
    [ ! -d "${__BASHIO_CACHE_DIR}" ]
}

@test "docker.registries.remove propagates an API failure" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    run bashio::docker.registries.remove "hub.docker.com"
    [ "${status}" -ne 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /docker/registries/hub.docker.com" ]
}
