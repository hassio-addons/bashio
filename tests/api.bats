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

@test "api.supervisor fails on a forbidden error (403)" {
    MOCK_BODY='{"result":"error","message":"forbidden"}'
    MOCK_STATUS='403'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails on a not-found error (404)" {
    MOCK_BODY='{"result":"error","message":"missing"}'
    MOCK_STATUS='404'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails on a method-not-allowed error (405)" {
    MOCK_BODY='{"result":"error","message":"nope"}'
    MOCK_STATUS='405'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails on an unexpected HTTP status with no error result" {
    # A non-200 status whose body does not carry a "result":"error" must still
    # be reported as a failure by the catch-all status check.
    MOCK_BODY='{"result":"ok"}'
    MOCK_STATUS='500'
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails when the request to curl itself fails" {
    curl() { return 1; }
    run bashio::api.supervisor GET /test
    [ "${status}" -ne 0 ]
}

@test "api.supervisor fails when the jq filter is invalid" {
    MOCK_BODY='{"result":"ok","data":{"hello":"world"}}'
    MOCK_STATUS='200'
    run bashio::api.supervisor GET /test false '.['
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

@test "api.supervisor keeps the POST body out of the curl arguments" {
    # Record argv, and resolve the --data-binary @file reference to its content.
    curl() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/argv"
        local prev='' arg body=''
        for arg in "$@"; do
            if [[ "${prev}" == "--data-binary" || "${prev}" == "--data" || "${prev}" == "-d" ]]; then
                body="${arg}"
            fi
            prev="${arg}"
        done
        if [[ "${body}" == @* ]]; then
            cat "${body:1}" >"${BATS_TEST_TMPDIR}/body"
        else
            printf '%s' "${body}" >"${BATS_TEST_TMPDIR}/body"
        fi
        cat >/dev/null
        printf '%s\n%s' '{"result":"ok"}' '200'
    }
    bashio::api.supervisor POST /test '{"password":"SUPER_SECRET_BODY"}' >/dev/null
    # The body must not appear in the process arguments...
    run cat "${BATS_TEST_TMPDIR}/argv"
    [[ "${output}" != *"SUPER_SECRET_BODY"* ]]
    # ...but must still be delivered to curl (via the data file).
    run cat "${BATS_TEST_TMPDIR}/body"
    [[ "${output}" == *"SUPER_SECRET_BODY"* ]]
}

@test "api.supervisor fails cleanly when the temp file cannot be created" {
    mktemp() { return 1; }
    msg=''
    bashio::log.error() { msg="$*"; }
    curl_called=0
    curl() {
        curl_called=1
        printf '%s\n%s' '{"result":"ok"}' '200'
    }
    rc=0
    bashio::api.supervisor POST /test '{}' >/dev/null || rc=$?
    # It must report the failure...
    [ "${rc}" -ne 0 ]
    [ -n "${msg}" ]
    # ...without ever reaching the network call.
    [ "${curl_called}" -eq 0 ]
}

@test "api.supervisor cleans up and fails if the body cannot be written" {
    # Point mktemp at a path whose parent directories do not exist (and are not
    # created), so the body write deterministically fails.
    local target="${BATS_TEST_TMPDIR}/missing/subdir/bashio-body"
    mktemp() { printf '%s' "${target}"; }
    msg=''
    bashio::log.error() { msg="$*"; }
    curl_called=0
    curl() {
        curl_called=1
        printf '%s\n%s' '{"result":"ok"}' '200'
    }
    rc=0
    bashio::api.supervisor POST /test '{"password":"x"}' >/dev/null || rc=$?
    # It must report the failure without sending the request...
    [ "${rc}" -ne 0 ]
    [ -n "${msg}" ]
    [ "${curl_called}" -eq 0 ]
    # ...and must not leave the body file behind.
    [ ! -e "${target}" ]
}

@test "api.supervisor GET does not depend on mktemp" {
    # A GET has no secret body, so it must not fail when mktemp is unavailable.
    mktemp() { return 1; }
    MOCK_BODY='{"result":"ok","data":{"hello":"world"}}'
    run bashio::api.supervisor GET /test false '.hello'
    [ "${status}" -eq 0 ]
    [ "${output}" = "world" ]
}

@test "api.supervisor never logs the request body" {
    log_out=''
    bashio::log.debug() { log_out+=" $*"; }
    bashio::log.trace() { log_out+=" $*"; }
    bashio::api.supervisor POST /test '{"password":"SECRET_IN_BODY"}' >/dev/null
    [[ "${log_out}" != *"SECRET_IN_BODY"* ]]
}
