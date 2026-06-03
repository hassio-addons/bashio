#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/config.sh.
#
# `bashio::config` reads the add-on options through `bashio::addon.config`
# (which normally calls the Supervisor API). That boundary is stubbed here with
# a fixed options document, so the real jq-based parsing logic is exercised.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    bashio::addon.config() {
        printf '%s' '{
            "username": "frenck",
            "port": 1234,
            "ssl": true,
            "debug": false,
            "blank": ""
        }'
    }
}

@test "config returns a string value" {
    run bashio::config "username"
    [ "${status}" -eq 0 ]
    [ "${output}" = "frenck" ]
}

@test "config returns the default for a missing key" {
    run bashio::config "missing" "fallback"
    [ "${status}" -eq 0 ]
    [ "${output}" = "fallback" ]
}

@test "config.exists succeeds for a present key" {
    run bashio::config.exists "username"
    [ "${status}" -eq 0 ]
}

@test "config.exists fails for a missing key" {
    run bashio::config.exists "missing"
    [ "${status}" -ne 0 ]
}

@test "config.has_value fails for an empty value" {
    run bashio::config.has_value "blank"
    [ "${status}" -ne 0 ]
}

@test "config.true succeeds for a true option" {
    run bashio::config.true "ssl"
    [ "${status}" -eq 0 ]
}

@test "config.false succeeds for a false option" {
    run bashio::config.false "debug"
    [ "${status}" -eq 0 ]
}

@test "config.equals matches a numeric value" {
    run bashio::config.equals "port" "1234"
    [ "${status}" -eq 0 ]
}

@test "config does not leak its options variable into the caller's scope" {
    # A caller may legitimately use a variable named 'options'; bashio::config
    # must not clobber it.
    options="caller-value"
    bashio::config "username" >/dev/null
    [ "${options}" = "caller-value" ]
}
