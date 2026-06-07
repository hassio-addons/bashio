#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with information from the resolution center.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::resolution() {
    local cache_key=${1:-'resolution.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'resolution.info' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'resolution.info'; then
        info=$(bashio::cache.get 'resolution.info')
    else
        info=$(bashio::api.supervisor GET /resolution/info false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get resolution info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'resolution.info' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    # Never overwrite the base blob with a filtered result: the
    # base blob is already cached above, so only cache under a distinct
    # caller-provided key.
    if [[ "${cache_key}" != 'resolution.info' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns a list of unsupported reasons.
# ------------------------------------------------------------------------------
function bashio::resolution.unsupported() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::resolution 'resolution.info.unsupported' '.unsupported[]'
}

# ------------------------------------------------------------------------------
# Returns a list of unhealthy reasons.
# ------------------------------------------------------------------------------
function bashio::resolution.unhealthy() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::resolution 'resolution.info.unhealthy' '.unhealthy[]'
}

# ------------------------------------------------------------------------------
# Returns the list of current issues from the resolution center.
# ------------------------------------------------------------------------------
function bashio::resolution.issues() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::resolution 'resolution.info.issues' '.issues[]'
}

# ------------------------------------------------------------------------------
# Returns the list of current suggestions from the resolution center.
# ------------------------------------------------------------------------------
function bashio::resolution.suggestions() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::resolution 'resolution.info.suggestions' '.suggestions[]'
}

# ------------------------------------------------------------------------------
# Returns the list of available checks from the resolution center.
# ------------------------------------------------------------------------------
function bashio::resolution.checks() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::resolution 'resolution.info.checks' '.checks[]'
}

# ------------------------------------------------------------------------------
# Applies a suggestion offered by the resolution center.
#
# Arguments:
#   $1 UUID of the suggestion to apply
# ------------------------------------------------------------------------------
function bashio::resolution.suggestion.apply() {
    local suggestion=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor POST "/resolution/suggestion/${suggestion}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Dismisses a suggestion offered by the resolution center.
#
# Arguments:
#   $1 UUID of the suggestion to dismiss
# ------------------------------------------------------------------------------
function bashio::resolution.suggestion.dismiss() {
    local suggestion=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor DELETE "/resolution/suggestion/${suggestion}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Dismisses an issue reported by the resolution center.
#
# Arguments:
#   $1 UUID of the issue to dismiss
# ------------------------------------------------------------------------------
function bashio::resolution.issue.dismiss() {
    local issue=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor DELETE "/resolution/issue/${issue}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Executes a check from the resolution center.
#
# Arguments:
#   $1 Slug of the check to run
# ------------------------------------------------------------------------------
function bashio::resolution.check() {
    local check=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor POST "/resolution/check/${check}/run" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Runs a backend healthcheck via the resolution center.
# ------------------------------------------------------------------------------
function bashio::resolution.healthcheck() {
    bashio::log.trace "${FUNCNAME[0]}"

    bashio::api.supervisor POST /resolution/healthcheck ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}
