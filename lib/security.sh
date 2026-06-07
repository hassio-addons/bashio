#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Supervisor security information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::security() {
    local cache_key=${1:-'security.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'security.info'; then
        info=$(bashio::cache.get 'security.info')
    else
        info=$(bashio::api.supervisor GET /security/info false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get security info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'security.info' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    # Never overwrite the base info blob with a filtered result: the
    # base blob is already cached above, so only cache under a distinct
    # caller-provided key.
    if [[ "${cache_key}" != 'security.info' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Sets one or more security options on the Supervisor.
#
# Arguments:
#   $1 Options to set (JSON object)
# ------------------------------------------------------------------------------
function bashio::security.options() {
    local options=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor POST /security/options "${options}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns or sets whether or not pwned password checks are enabled.
#
# Arguments:
#   $1 True to enable pwned checks, false otherwise (optional).
# ------------------------------------------------------------------------------
function bashio::security.pwned() {
    local pwned=${1:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${pwned}"; then
        # Normalize to a strict boolean so an arbitrary value cannot inject
        # extra fields into the options JSON through the raw-JSON prefix.
        if bashio::var.true "${pwned}"; then
            pwned=$(bashio::var.json pwned "^true")
        else
            pwned=$(bashio::var.json pwned "^false")
        fi
        bashio::api.supervisor POST /security/options "${pwned}" ||
            return "${__BASHIO_EXIT_NOK}"
        bashio::cache.flush_all
    else
        bashio::security 'security.info.pwned' '.pwned // false'
    fi
}

# ------------------------------------------------------------------------------
# Returns or sets whether or not security is forced.
#
# Arguments:
#   $1 True to force security, false otherwise (optional).
# ------------------------------------------------------------------------------
function bashio::security.force_security() {
    local force=${1:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${force}"; then
        # Normalize to a strict boolean so an arbitrary value cannot inject
        # extra fields into the options JSON through the raw-JSON prefix.
        if bashio::var.true "${force}"; then
            force=$(bashio::var.json force_security "^true")
        else
            force=$(bashio::var.json force_security "^false")
        fi
        bashio::api.supervisor POST /security/options "${force}" ||
            return "${__BASHIO_EXIT_NOK}"
        bashio::cache.flush_all
    else
        bashio::security 'security.info.force_security' '.force_security // false'
    fi
}
