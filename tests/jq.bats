#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/jq.sh (JSON query helpers).
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

@test "jq applies a filter to a JSON string" {
    run bashio::jq '{"name":"bashio","count":3}' '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "bashio" ]
}

@test "jq.exists succeeds when the filtered value exists" {
    run bashio::jq.exists '{"name":"bashio"}' '.name'
    [ "${status}" -eq 0 ]
}

@test "jq.exists fails when the filtered value is null" {
    run bashio::jq.exists '{"name":"bashio"}' '.missing'
    [ "${status}" -ne 0 ]
}

@test "jq.is_string detects a string" {
    run bashio::jq.is_string '{"name":"bashio"}' '.name'
    [ "${status}" -eq 0 ]
}

@test "jq.is_number detects a number" {
    run bashio::jq.is_number '{"count":3}' '.count'
    [ "${status}" -eq 0 ]
}

@test "jq.is_string is false for a number" {
    run bashio::jq.is_string '{"count":3}' '.count'
    [ "${status}" -ne 0 ]
}

@test "jq.has_value succeeds for a non-empty result" {
    run bashio::jq.has_value '{"items":[1,2]}' '.items'
    [ "${status}" -eq 0 ]
}

@test "jq.has_value fails for an empty array" {
    run bashio::jq.has_value '{"items":[]}' '.items'
    [ "${status}" -ne 0 ]
}
