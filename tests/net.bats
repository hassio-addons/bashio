#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/net.sh.
#
# bashio::net.wait_for blocks until a TCP port is reachable, then returns
# __BASHIO_EXIT_OK. It always returns OK - failures are suppressed with
# `|| true` and a timeout is used so it never hangs forever.
#
# To exercise the "port becomes available" path without relying on external
# services we use netcat (nc) to open a listener on a random high port, then
# call wait_for against it with a short timeout. The "port never opens" case
# is exercised with a very short timeout against a port nothing is listening on.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    LOG_FD=1
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_OFF}" # keep trace output silent
    __BASHIO_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
    __BASHIO_LOG_TIMESTAMP="%T"
}

# ---------------------------------------------------------------------------
# Return-code contract: always __BASHIO_EXIT_OK regardless of outcome
# ---------------------------------------------------------------------------

@test "net.wait_for returns OK even when the port never opens (timeout)" {
    # Port 19999 is almost certainly not listening; timeout of 1 second.
    run bashio::net.wait_for 19999 127.0.0.1 1
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "net.wait_for returns OK for an immediately available port" {
    # Find a free port and open a listener with nc.
    local port=19876
    # Start a simple listener that accepts one connection and exits.
    nc -l -p "${port}" 127.0.0.1 >/dev/null 2>&1 &
    local nc_pid=$!
    # Give the listener a moment to bind.
    sleep 0.2
    local before after elapsed
    before="$(date +%s)"
    run bashio::net.wait_for "${port}" 127.0.0.1 5
    after="$(date +%s)"
    elapsed=$((after - before))
    # Clean up the listener regardless of test outcome.
    kill "${nc_pid}" 2>/dev/null || true
    wait "${nc_pid}" 2>/dev/null || true
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    # The port was already open, so the call must return quickly (well under 2 s).
    [ "${elapsed}" -lt 2 ]
}

# ---------------------------------------------------------------------------
# Default argument handling
# ---------------------------------------------------------------------------

@test "net.wait_for falls back to localhost when host argument is empty" {
    # Port 19998 unlikely to be open; timeout of 1 second; empty host falls back to localhost.
    run bashio::net.wait_for 19998 "" 1
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
}

@test "net.wait_for does not hang beyond its explicit timeout when port is unreachable" {
    # The function internally defaults to 60-second timeout.
    # We supply an explicit short timeout to keep the suite fast.
    local before after elapsed
    before="$(date +%s)"
    run bashio::net.wait_for 19997 127.0.0.1 2
    after="$(date +%s)"
    elapsed=$((after - before))
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    # Must finish well inside the 2-second window (allow 5 s for slow CI).
    [ "${elapsed}" -lt 5 ]
}

# ---------------------------------------------------------------------------
# Output contract: the function must not produce visible output
# ---------------------------------------------------------------------------

@test "net.wait_for emits no output on stdout when port is unreachable" {
    run bashio::net.wait_for 19996 127.0.0.1 1
    [ "${status}" -eq "${__BASHIO_EXIT_OK}" ]
    [ -z "${output}" ]
}
