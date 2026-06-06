#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with the available ingress panels.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::ingress.panels() {
    local cache_key=${1:-'ingress.panels'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'ingress.panels'; then
        info=$(bashio::cache.get 'ingress.panels')
    else
        info=$(bashio::api.supervisor GET /ingress/panels false '.panels')
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get ingress panels from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'ingress.panels' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    bashio::cache.set "${cache_key}" "${response}"
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Creates a new ingress session and returns its session identifier.
# ------------------------------------------------------------------------------
function bashio::ingress.session() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /ingress/session '{}' '.session' ||
        return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Validates an ingress session and extends how long it stays valid.
#
# Arguments:
#   $1 Ingress session identifier
# ------------------------------------------------------------------------------
function bashio::ingress.validate_session() {
    local session=${1}
    local payload

    # The session id is effectively a credential, so it is kept out of the
    # trace log (only the function name is logged).
    bashio::log.trace "${FUNCNAME[0]}"

    payload=$(bashio::var.json session "${session}")
    bashio::api.supervisor POST /ingress/validate_session "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"

    return "${__BASHIO_EXIT_OK}"
}
