#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/exit.sh.
#
# These functions terminate the script with `exit`, so they are always invoked
# through bats' `run` (which runs them in a subshell and captures the exit
# status). LOG_FD is pointed at fd 1 and the log globals are pinned so the
# fatal/warning messages they emit can be asserted on.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    LOG_FD=1
    __BASHIO_LOG_LEVEL=5 # INFO: lets warning/fatal through, keeps trace quiet
    __BASHIO_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
    __BASHIO_LOG_TIMESTAMP="%T"
}

@test "exit.ok terminates with the success code" {
    run bashio::exit.ok
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "exit.nok terminates with the failure code" {
    run bashio::exit.nok
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "exit.nok logs the message at fatal level before exiting" {
    run bashio::exit.nok "something broke"
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
    [[ "${output}" == *"FATAL"* ]]
    [[ "${output}" == *"something broke"* ]]
}

@test "die_if_false exits when the value is false" {
    run bashio::exit.die_if_false "false"
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "die_if_false continues when the value is true" {
    run bashio::exit.die_if_false "true"
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "die_if_true exits when the value is true" {
    run bashio::exit.die_if_true "true"
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "die_if_true continues when the value is false" {
    run bashio::exit.die_if_true "false"
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "die_if_empty exits when the value is empty" {
    run bashio::exit.die_if_empty ""
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
}

@test "die_if_empty continues when the value is non-empty" {
    run bashio::exit.die_if_empty "present"
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "the die_if_* helpers forward their message to the fatal log" {
    run bashio::exit.die_if_true "true" "boom from die_if_true"
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
    [[ "${output}" == *"boom from die_if_true"* ]]
}

@test "the deprecated die_if_true alias warns and still delegates" {
    # Triggering case: still exits with the failure code...
    run hass.die_if_true "true" # codespell:ignore
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
    [[ "${output}" == *"deprecated"* ]]
    # Non-triggering case: continues, but the deprecation warning is emitted.
    run hass.die_if_true "false" # codespell:ignore
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    [[ "${output}" == *"deprecated"* ]]
}

@test "the deprecated die_if_empty alias warns and still delegates" {
    run hass.die_if_empty "" # codespell:ignore
    [ "${status}" -eq "${__BASHIO_EXIT_NOK}" ]
    [[ "${output}" == *"deprecated"* ]]
    run hass.die_if_empty "present" # codespell:ignore
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    [[ "${output}" == *"deprecated"* ]]
}
