#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with generic information about the Docker configuration.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::docker() {
    local cache_key=${1:-'docker.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'docker.info'; then
        info=$(bashio::cache.get 'docker.info')
    else
        info=$(bashio::api.supervisor GET /docker/info false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get docker info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'docker.info' "${info}"
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
# Returns the version of Docker in use.
# ------------------------------------------------------------------------------
function bashio::docker.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::docker 'docker.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the storage driver Docker is using.
# ------------------------------------------------------------------------------
function bashio::docker.storage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::docker 'docker.info.storage' '.storage'
}

# ------------------------------------------------------------------------------
# Returns the logging driver Docker is using.
# ------------------------------------------------------------------------------
function bashio::docker.logging() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::docker 'docker.info.logging' '.logging'
}

# ------------------------------------------------------------------------------
# Returns whether or not IPv6 is enabled for the Docker network.
# ------------------------------------------------------------------------------
function bashio::docker.enable_ipv6() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::docker 'docker.info.enable_ipv6' '.enable_ipv6 // false'
}

# ------------------------------------------------------------------------------
# Returns the MTU configured for the Docker network.
# ------------------------------------------------------------------------------
function bashio::docker.mtu() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::docker 'docker.info.mtu' '.mtu'
}

# ------------------------------------------------------------------------------
# Sets Docker options.
#
# Arguments:
#   $1 Options object (JSON)
# ------------------------------------------------------------------------------
function bashio::docker.options() {
    local options=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor POST /docker/options "${options}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with the configured Docker registries.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::docker.registries() {
    local cache_key=${1:-'docker.registries'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'docker.registries'; then
        info=$(bashio::cache.get 'docker.registries')
    else
        info=$(bashio::api.supervisor GET /docker/registries false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get docker registries from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'docker.registries' "${info}"
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
# Adds a Docker registry.
#
# Arguments:
#   $1 Hostname of the registry
#   $2 Username for the registry
#   $3 Password for the registry
# ------------------------------------------------------------------------------
function bashio::docker.registries.add() {
    local hostname=${1}
    local username=${2}
    local password=${3}
    local credentials
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "${hostname}"

    # The API expects {"<hostname>": {"username": ..., "password": ...}}.
    # Build it with bashio::var.json so untrusted values are JSON escaped
    # instead of being interpolated into a jq program.
    credentials=$(bashio::var.json \
        username "${username}" \
        password "${password}")
    payload=$(bashio::var.json "${hostname}" "^${credentials}")

    bashio::api.supervisor POST /docker/registries "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Removes a Docker registry.
#
# Arguments:
#   $1 Hostname of the registry
# ------------------------------------------------------------------------------
function bashio::docker.registries.remove() {
    local hostname=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor DELETE "/docker/registries/${hostname}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}
