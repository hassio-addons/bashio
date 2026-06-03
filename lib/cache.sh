#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Check if a cache key exists in the cache
#
# Arguments:
#   $1 Cache key
# ------------------------------------------------------------------------------
function bashio::cache.exists() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

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

    bashio::log.trace "${FUNCNAME[0]}" "$@"

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

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if ! bashio::fs.directory_exists "${__BASHIO_CACHE_DIR}"; then
        # Cached values can contain secrets, so create the directory with an
        # owner-only umask instead of relying on the (predictable) default
        # permissions. A subshell keeps the umask change local to this call.
        (umask 077 && mkdir -p "${__BASHIO_CACHE_DIR}") ||
            bashio::exit.nok "Could not create cache folder"
    fi

    # Enforce owner-only access even if the directory already existed, for
    # example one left behind by an older version with broader permissions.
    if ! chmod 0700 "${__BASHIO_CACHE_DIR}"; then
        bashio::log.warning "Could not restrict permissions on the cache folder"
    fi

    if ! printf "%s" "$value" >"${__BASHIO_CACHE_DIR}/${key}.cache"; then
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

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if ! rm -f "${__BASHIO_CACHE_DIR}/${key}.cache"; then
        bashio::exit.nok "An error occurred while flushing ${key} from cache"
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
