#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/var.sh
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

@test "bashio::var.true succeeds for 'true'" {
    run bashio::var.true "true"
    [ "${status}" -eq 0 ]
}

@test "bashio::var.true fails for any other value" {
    run bashio::var.true "false"
    [ "${status}" -ne 0 ]
}

@test "bashio::var.false succeeds for 'false'" {
    run bashio::var.false "false"
    [ "${status}" -eq 0 ]
}

@test "bashio::var.has_value succeeds for a non-empty value" {
    run bashio::var.has_value "something"
    [ "${status}" -eq 0 ]
}

@test "bashio::var.has_value fails for an empty value" {
    run bashio::var.has_value ""
    [ "${status}" -ne 0 ]
}

@test "bashio::var.is_empty succeeds for an empty value" {
    run bashio::var.is_empty ""
    [ "${status}" -eq 0 ]
}

@test "bashio::var.equals succeeds for equal values" {
    run bashio::var.equals "abc" "abc"
    [ "${status}" -eq 0 ]
}

@test "bashio::var.equals fails for different values" {
    run bashio::var.equals "abc" "xyz"
    [ "${status}" -ne 0 ]
}
