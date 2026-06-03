#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/api.sh (the Supervisor API client).
#
# The network boundary is stubbed by shadowing `curl` with a Bash function, so
# no real HTTP requests are made. The stub emits a canned response body followed
# by an HTTP status code, mimicking the real call that uses
# `curl --write-out '\n%{http_code}'`.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    MOCK_BODY='{}'
    MOCK_STATUS='200'
    curl() {
        printf '%s\n%s' "${MOCK_BODY}" "${MOCK_STATUS}"
    }
}

@test "api.supervisor returns the filtered data on a successful response" {
    MOCK_BODY='{"result":"ok","data":{"hello":"world"}}'
    MOCK_STATUS='200'
    run bashio::api.supervisor GET /test false '.hello'
    [ "${status}" -eq 0 ]
    [ "${output}" = "world" ]
}

@test "api.supervisor returns the raw body when raw output is requested" {
    MOCK_BODY='just-raw-text'
    MOCK_STATUS='200'
    run bashio::api.supervisor GET /test true
    [ "${status}" -eq 0 ]
    [ "${output}" = "just-raw-text" ]
}

@test "api.supervisor fails on an authentication error (401)" {
    MOCK_BODY='{"result":"error","message":"unauthorized"}'
    MOCK_STATUS='401'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails on a not-found error (404)" {
    MOCK_BODY='{"result":"error","message":"missing"}'
    MOCK_STATUS='404'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails when the API reports an error result" {
    MOCK_BODY='{"result":"error","message":"boom"}'
    MOCK_STATUS='200'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor keeps the auth token out of the curl arguments" {
    __BASHIO_SUPERVISOR_TOKEN="SUPER_SECRET_TOKEN"
    # Record curl's arguments and its stdin (the -H @- header) separately.
    curl() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/argv"
        cat >"${BATS_TEST_TMPDIR}/stdin"
        printf '%s\n%s' '{"result":"ok"}' '200'
    }
    bashio::api.supervisor GET /test true >/dev/null
    # The token must not appear in the process arguments...
    run cat "${BATS_TEST_TMPDIR}/argv"
    [[ "${output}" != *"SUPER_SECRET_TOKEN"* ]]
    # ...but must be supplied via stdin (the -H @- header).
    run cat "${BATS_TEST_TMPDIR}/stdin"
    [[ "${output}" == *"SUPER_SECRET_TOKEN"* ]]
}
