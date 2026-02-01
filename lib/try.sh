#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is a bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

declare __BASHIO_TRY_EXIT_STATUS=0

# ------------------------------------------------------------------------------
# Executes a command/function in a subshell with enabled and effective errexit
# option and saves it's exit status.
#
# Arguments: $* Command/function and it's arguments
#
#
# Use this function to get the exit status of a subshell for a condition (eg.
# 'if') without disabling errexit option in it. All Bashio functions that
# execute changes through the API are depend on enabled errexit option.
#
# Simple example:
#   ~ # function test { false; echo "Don't print it"; }
#   ~ # if ! test; then echo "Print it"; fi
#   Don't print it
#   ~ # bashio::try test
#   ~ # if bashio::try.failed; then echo "Print it"; fi
#   Print it
# ------------------------------------------------------------------------------
function bashio::try {
    set +e
    (set -e; "$@")
    __BASHIO_TRY_EXIT_STATUS=$?
    set -e
}

# ------------------------------------------------------------------------------
# Checks whether that last command executed by bashio::try has suceeded.
# ------------------------------------------------------------------------------
function bashio::try.succeeded {
    if ((__BASHIO_TRY_EXIT_STATUS)); then
        return "${__BASHIO_EXIT_NOK}"
    else
        return "${__BASHIO_EXIT_OK}"
    fi
}

# ------------------------------------------------------------------------------
# Checks whether that last command executed by bashio::try has failed.
# ------------------------------------------------------------------------------
function bashio::try.failed {
    if ((__BASHIO_TRY_EXIT_STATUS)); then
        return "${__BASHIO_EXIT_OK}"
    else
        return "${__BASHIO_EXIT_NOK}"
    fi
}
