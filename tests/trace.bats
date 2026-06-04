#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/trace.sh.
#
# bashio::trace() returns __BASHIO_EXIT_OK (0) when the current log level is
# at or above __BASHIO_LOG_LEVEL_TRACE (7), and __BASHIO_EXIT_NOK (1)
# otherwise. The log globals are pinned in setup() because the `declare`d
# defaults do not survive bats re-sourcing.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    LOG_FD=1
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"  # 5 - well below trace (7)
    __BASHIO_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
    __BASHIO_LOG_TIMESTAMP="%T"
}

# ---------------------------------------------------------------------------
# Below-trace levels: function must return NOK
# ---------------------------------------------------------------------------

@test "trace returns NOK when log level is OFF (0)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_OFF}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace returns NOK when log level is FATAL (1)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_FATAL}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace returns NOK when log level is ERROR (2)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_ERROR}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace returns NOK when log level is WARNING (3)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_WARNING}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace returns NOK when log level is NOTICE (4)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_NOTICE}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace returns NOK when log level is INFO (5)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace returns NOK when log level is DEBUG (6)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_DEBUG}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

# ---------------------------------------------------------------------------
# At-or-above-trace levels: function must return OK
# ---------------------------------------------------------------------------

@test "trace returns OK when log level is TRACE (7) - exact boundary" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_TRACE}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "trace returns OK when log level is ALL (8)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_ALL}"
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

# ---------------------------------------------------------------------------
# Output: the function must not emit anything to stdout
# ---------------------------------------------------------------------------

@test "trace emits no output when returning NOK" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"
    run bashio::trace
    [ -z "${output}" ]
}

@test "trace emits no output when returning OK" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_TRACE}"
    run bashio::trace
    [ -z "${output}" ]
}

# ---------------------------------------------------------------------------
# Boundary relationship: trace threshold is strictly higher than debug
# ---------------------------------------------------------------------------

@test "trace is stricter than debug - DEBUG level enables debug but not trace" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_DEBUG}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "trace and debug are both enabled at TRACE level" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_TRACE}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    run bashio::trace
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

# ---------------------------------------------------------------------------
# Usability in an if-statement (non-run form)
# ---------------------------------------------------------------------------

@test "trace can be used directly in an if-statement - false branch" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"
    local reached=false
    if bashio::trace; then
        reached=true
    fi
    [ "${reached}" = "false" ]
}

@test "trace can be used directly in an if-statement - true branch" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_TRACE}"
    local reached=false
    if bashio::trace; then
        reached=true
    fi
    [ "${reached}" = "true" ]
}
