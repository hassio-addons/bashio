#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Check if a cache key exists in the cache
#
# Arguments:
#   $1 Cache key
# ------------------------------------------------------------------------------
function bashio::cache.exists() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::fs.file_exists "${__BASHIO_CACHE_DIR}/${key}.cache"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Returns the cached value based on a key
#
# Arguments:
#   $1 Cache key
# ------------------------------------------------------------------------------
function bashio::cache.get() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::cache.exists "${key}"; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    printf "%s" "$(<"${__BASHIO_CACHE_DIR}/${key}.cache")"
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Cache a value identified by a given key
#
# Arguments:
#   $1 Cache key
#   $2 Cache value
# ------------------------------------------------------------------------------
function bashio::cache.set() {
    local key=${1}
    local value=${2}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::fs.directory_exists "${__BASHIO_CACHE_DIR}"; then
        mkdir -p "${__BASHIO_CACHE_DIR}" ||
            bashio::exit.nok "Could not create cache folder"
    fi

    if ! printf "%s" "$value" > "${__BASHIO_CACHE_DIR}/${key}.cache"; then
        bashio::log.warning "An error occurred while storing ${key} to cache"
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Remove a specific item from the cache based on the caching key
#
# Arguments:
#   $1 Cache key
# ------------------------------------------------------------------------------
function bashio::cache.flush() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! rm -f "${__BASHIO_CACHE_DIR}/${key}.cache"; then
        bashio::exit.nok "An error while flushing ${key} from cache"
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Flush all cached data
# ------------------------------------------------------------------------------
bashio::cache.flush_all() {
    bashio::log.trace "${FUNCNAME[0]}"

    if ! bashio::fs.directory_exists "${__BASHIO_CACHE_DIR}"; then
         return "${__BASHIO_EXIT_OK}"
    fi

    if ! rm -f -r "${__BASHIO_CACHE_DIR}"; then
        bashio::exit.nok "Could not flush cache"
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}
