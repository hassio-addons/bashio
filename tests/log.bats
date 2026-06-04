#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/log.sh.
#
# The log helpers write to the fd in $LOG_FD (a dup of the original STDOUT) so
# that logging bypasses `$(...)` capture. For these tests we point $LOG_FD at
# fd 1, so bats' `run` captures the emitted lines directly. The configured log
# level is reset in setup() so the level-gating tests are deterministic.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    LOG_FD=1
    # Set the runtime log globals explicitly. Bashio's `declare`d defaults do
    # not survive the way bats re-sources the library, so the suite must not
    # depend on them; pin them to the documented defaults instead.
    __BASHIO_LOG_LEVEL=5 # INFO, the default
    __BASHIO_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
    __BASHIO_LOG_TIMESTAMP="%T"
}

@test "log joins all of its arguments into one line" {
    run bashio::log one two three
    [ "${status}" -eq 0 ]
    [ "${output}" = "one two three" ]
}

@test "the colour helpers wrap the message in their own colour code" {
    run bashio::log.red x
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_RED}x${__BASHIO_COLORS_RESET}")" ]
    run bashio::log.green x
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_GREEN}x${__BASHIO_COLORS_RESET}")" ]
    run bashio::log.yellow x
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_YELLOW}x${__BASHIO_COLORS_RESET}")" ]
    run bashio::log.blue x
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BLUE}x${__BASHIO_COLORS_RESET}")" ]
    run bashio::log.magenta x
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_MAGENTA}x${__BASHIO_COLORS_RESET}")" ]
    run bashio::log.cyan x
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_CYAN}x${__BASHIO_COLORS_RESET}")" ]
}

@test "log.log substitutes every placeholder in the format" {
    run bashio::log.log "${__BASHIO_LOG_LEVEL_INFO}" "hello"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"INFO: hello"* ]]
    # No template placeholder may survive into the output.
    [[ "${output}" != *"{TIMESTAMP}"* ]]
    [[ "${output}" != *"{LEVEL}"* ]]
    [[ "${output}" != *"{MESSAGE}"* ]]
}

@test "log.log suppresses a message above the configured level" {
    run bashio::log.log "${__BASHIO_LOG_LEVEL_DEBUG}" "should not appear"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "log.info emits a green INFO line at the default level" {
    run bashio::log.info "ready"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"INFO"* ]]
    [[ "${output}" == *"ready"* ]]
    [[ "${output}" == *"$(printf '%b' "${__BASHIO_COLORS_GREEN}")"* ]]
}

@test "log.debug and log.trace are silent at the default (INFO) level" {
    run bashio::log.debug "debug message"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    run bashio::log.trace "trace message"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "every level helper emits when the level is set to ALL" {
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_ALL}"
    for helper in trace debug info notice warning error fatal; do
        run "bashio::log.${helper}" "msg-${helper}"
        [ "${status}" -eq 0 ]
        [[ "${output}" == *"msg-${helper}"* ]]
    done
}

@test "log.level maps names to numeric levels case-insensitively" {
    bashio::log.level "DEBUG"
    [ "${__BASHIO_LOG_LEVEL}" -eq "${__BASHIO_LOG_LEVEL_DEBUG}" ]
}

@test "log.level accepts the 'critical' alias for fatal" {
    bashio::log.level critical
    [ "${__BASHIO_LOG_LEVEL}" -eq "${__BASHIO_LOG_LEVEL_FATAL}" ]
}

@test "log.level off silences even fatal messages" {
    bashio::log.level off
    [ "${__BASHIO_LOG_LEVEL}" -eq "${__BASHIO_LOG_LEVEL_OFF}" ]
    run bashio::log.fatal "boom"
    [ -z "${output}" ]
}

@test "log.level rejects an unknown level" {
    run bashio::log.level "bogus"
    [ "${status}" -ne 0 ]
}

@test "log.level takes effect on subsequent log calls" {
    run bashio::log.debug "before"
    [ -z "${output}" ]
    bashio::log.level debug
    run bashio::log.debug "after"
    [ -n "${output}" ]
    [[ "${output}" == *"after"* ]]
}

@test "log.reinitialize_output succeeds and logging keeps working" {
    run bashio::log.reinitialize_output
    [ "${status}" -eq 0 ]
    run bashio::log "still logging"
    [ "${output}" = "still logging" ]
}
