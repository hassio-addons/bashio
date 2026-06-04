#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Authenticates a Home Assistant user against the Supervisor auth backend.
#
# The Supervisor signals the outcome via the HTTP status: a valid set of
# credentials returns 200, while invalid credentials return 401. That maps
# directly onto the return code of bashio::api.supervisor, so a successful
# call means the user authenticated.
#
# The password is never logged: a placeholder is traced instead and the
# request body is routed through api.supervisor, which keeps POST bodies out
# of the process list and the trace log.
#
# Arguments:
#   $1 Username of the Home Assistant user
#   $2 Password of the Home Assistant user
# ------------------------------------------------------------------------------
function bashio::auth() {
    local username=${1}
    local password=${2}
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "${username}" "<REDACTED PASSWORD>"

    payload=$(bashio::var.json \
        username "${username}" \
        password "${password}")

    bashio::api.supervisor POST /auth "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Lists the Home Assistant users known to the Supervisor auth backend.
# ------------------------------------------------------------------------------
function bashio::auth.list() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /auth/list false ".users"
}

# ------------------------------------------------------------------------------
# Resets the password of a Home Assistant user.
#
# The password is never logged: a placeholder is traced instead and the
# request body is routed through api.supervisor, which keeps POST bodies out
# of the process list and the trace log.
#
# Arguments:
#   $1 Username of the Home Assistant user
#   $2 New password for the Home Assistant user
# ------------------------------------------------------------------------------
function bashio::auth.reset() {
    local username=${1}
    local password=${2}
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "${username}" "<REDACTED PASSWORD>"

    payload=$(bashio::var.json \
        username "${username}" \
        password "${password}")

    bashio::api.supervisor POST /auth/reset "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Clears the Supervisor auth cache.
# ------------------------------------------------------------------------------
function bashio::auth.cache.reset() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor DELETE /auth/cache || return "${__BASHIO_EXIT_NOK}"
    return "${__BASHIO_EXIT_OK}"
}
