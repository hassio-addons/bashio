#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Wait for a TCP port to be available.
#
# Arguments:
#   $1 Port to wait for
#   $2 Interface/host the port should bind to (optional, default: localhost)
#   $3 Timeout in seconds (option, defaults: 60)
# ------------------------------------------------------------------------------
bashio::net.wait_for() {
    local port=${1}
    local host=${2:-'localhost'}
    local timeout=${3:-60}
    local timeout_argument=""

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if timeout -t 1337 true > /dev/null 2>&1; then
        timeout_argument="-t"
    fi

    timeout ${timeout_argument} "${timeout}" \
        bash -c \
            "until echo > /dev/tcp/${host}/${port} ; do sleep 0.5; done" \
                > /dev/null 2>&1 || true;

    return "${__BASHIO_EXIT_OK}"
}
