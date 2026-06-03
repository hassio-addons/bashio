#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/string.sh
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

@test "bashio::string.lower lowercases a string" {
    run bashio::string.lower "HeLLo World"
    [ "${status}" -eq 0 ]
    [ "${output}" = "hello world" ]
}

@test "bashio::string.upper uppercases a string" {
    run bashio::string.upper "HeLLo World"
    [ "${status}" -eq 0 ]
    [ "${output}" = "HELLO WORLD" ]
}

@test "bashio::string.length returns the length of a string" {
    run bashio::string.length "abcde"
    [ "${status}" -eq 0 ]
    [ "${output}" = "5" ]
}

@test "bashio::string.length of an empty string is zero" {
    run bashio::string.length ""
    [ "${status}" -eq 0 ]
    [ "${output}" = "0" ]
}

@test "bashio::string.replace replaces all occurrences of a substring" {
    run bashio::string.replace "foobarfoo" "foo" "baz"
    [ "${status}" -eq 0 ]
    [ "${output}" = "bazbarbaz" ]
}

@test "bashio::string.substring returns the rest from a position" {
    run bashio::string.substring "abcABC123" 6
    [ "${status}" -eq 0 ]
    [ "${output}" = "123" ]
}

@test "bashio::string.substring returns a slice with a length" {
    run bashio::string.substring "abcABC123" 3 3
    [ "${status}" -eq 0 ]
    [ "${output}" = "ABC" ]
}

@test "bashio::string.replace treats an asterisk needle literally" {
    run bashio::string.replace "a*b*c" "*" "-"
    [ "${status}" -eq 0 ]
    [ "${output}" = "a-b-c" ]
}

@test "bashio::string.replace treats a question-mark needle literally" {
    run bashio::string.replace "a?b" "?" "-"
    [ "${status}" -eq 0 ]
    [ "${output}" = "a-b" ]
}
