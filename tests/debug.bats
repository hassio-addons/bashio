#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/debug.sh.
#
# bashio::debug() returns __BASHIO_EXIT_OK (0) when the current log level is
# at or above __BASHIO_LOG_LEVEL_DEBUG (6), and __BASHIO_EXIT_NOK (1)
# otherwise. The log globals are pinned in setup() because the `declare`d
# defaults do not survive bats re-sourcing.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    LOG_FD=1
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"  # 5 - below debug (6)
    __BASHIO_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
    __BASHIO_LOG_TIMESTAMP="%T"
}

# ---------------------------------------------------------------------------
# Below-debug levels: function must return NOK
# ---------------------------------------------------------------------------

@test "debug returns NOK when log level is OFF (0)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_OFF}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "debug returns NOK when log level is FATAL (1)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_FATAL}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "debug returns NOK when log level is ERROR (2)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_ERROR}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "debug returns NOK when log level is WARNING (3)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_WARNING}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "debug returns NOK when log level is NOTICE (4)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_NOTICE}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "debug returns NOK when log level is INFO (5) - default" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

# ---------------------------------------------------------------------------
# At-or-above-debug levels: function must return OK
# ---------------------------------------------------------------------------

@test "debug returns OK when log level is DEBUG (6) - exact boundary" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_DEBUG}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "debug returns OK when log level is TRACE (7)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_TRACE}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "debug returns OK when log level is ALL (8)" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_ALL}"
    run bashio::debug
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

# ---------------------------------------------------------------------------
# Output: the function must not emit anything to stdout
# ---------------------------------------------------------------------------

@test "debug emits no output when returning NOK" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"
    run bashio::debug
    [ -z "${output}" ]
}

@test "debug emits no output when returning OK" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_DEBUG}"
    run bashio::debug
    [ -z "${output}" ]
}

# ---------------------------------------------------------------------------
# Usability in an if-statement (non-run form)
# ---------------------------------------------------------------------------

@test "debug can be used directly in an if-statement - false branch" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_INFO}"
    local reached=false
    if bashio::debug; then
        reached=true
    fi
    [ "${reached}" = "false" ]
}

@test "debug can be used directly in an if-statement - true branch" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_DEBUG}"
    local reached=false
    if bashio::debug; then
        reached=true
    fi
    [ "${reached}" = "true" ]
}
