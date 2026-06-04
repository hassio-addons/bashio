#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/try.sh.
#
# bashio::try runs a command in an errexit subshell and records its exit status
# in __BASHIO_TRY_EXIT_STATUS, so callers can branch on it (via try.succeeded /
# try.failed) without disabling errexit in the surrounding scope.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

@test "try records success for a passing command" {
    bashio::try true
    run bashio::try.succeeded
    [ "${status}" -eq 0 ]
    run bashio::try.failed
    [ "${status}" -ne 0 ]
}

@test "try records failure for a failing command" {
    bashio::try false
    run bashio::try.succeeded
    [ "${status}" -ne 0 ]
    run bashio::try.failed
    [ "${status}" -eq 0 ]
}

@test "try.succeeded and try.failed can be used directly in a condition" {
    # Direct (non-run) use is the documented pattern.
    bashio::try true
    bashio::try.succeeded
    ! bashio::try.failed

    bashio::try false
    bashio::try.failed
    ! bashio::try.succeeded
}

@test "try forwards arguments to the command" {
    local marker="${BATS_TEST_TMPDIR}/arg"
    record() { printf '%s' "$2" >"${marker}"; }
    bashio::try record first second
    [ "$(cat "${marker}")" = "second" ]
    bashio::try.succeeded
}

@test "try stops a function at the first failing command via subshell errexit" {
    local marker="${BATS_TEST_TMPDIR}/after"
    failing() {
        false
        : >"${marker}"
    }
    bashio::try failing
    # The command failed, so try.failed must report it...
    run bashio::try.failed
    [ "${status}" -eq 0 ]
    # ...and the statement after the failing command must not have run.
    [ ! -e "${marker}" ]
}

@test "try keeps errexit enabled in the calling scope afterwards" {
    bashio::try false
    [[ $- == *e* ]]
}

@test "try.succeeded reflects only the most recent try" {
    bashio::try false
    bashio::try true
    run bashio::try.succeeded
    [ "${status}" -eq 0 ]
}
