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

@test "bashio::var.json builds a JSON object from key/value pairs" {
    run bashio::var.json key "value"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"key":"value"}' ]
}

@test "bashio::var.json treats a ^-prefixed value as raw JSON" {
    run bashio::var.json count "^42"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"count":42}' ]
}

@test "bashio::var.json escapes special characters in the key" {
    run bashio::var.json 'a"b' "value"
    [ "${status}" -eq 0 ]
    # The output must be valid JSON whose single key is the literal input,
    # with no structure injected by the embedded quote.
    [ "$(jq -r 'to_entries | length' <<<"${output}")" = "1" ]
    [ "$(jq -r 'to_entries[0].key' <<<"${output}")" = 'a"b' ]
    [ "$(jq -r 'to_entries[0].value' <<<"${output}")" = "value" ]
}

@test "bashio::var.json escapes a backslash in the key" {
    run bashio::var.json 'a\b' "value"
    [ "${status}" -eq 0 ]
    [ "$(jq -r 'to_entries | length' <<<"${output}")" = "1" ]
    [ "$(jq -r 'to_entries[0].key' <<<"${output}")" = 'a\b' ]
    [ "$(jq -r 'to_entries[0].value' <<<"${output}")" = "value" ]
}

@test "bashio::var.json fails for an odd number of arguments" {
    run bashio::var.json only-a-key
    [ "${status}" -ne 0 ]
}

@test "bashio::var.json_string escapes a string for JSON" {
    run bashio::var.json_string 'he said "hi"'
    [ "${status}" -eq 0 ]
    [ "${output}" = '"he said \"hi\""' ]
}
