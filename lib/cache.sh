#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Checks that a cache key is a safe filename, to prevent path traversal.
#
# The key is interpolated into the path "${__BASHIO_CACHE_DIR}/<key>.cache", so
# it must be a single path component: a slash or other unexpected character
# could read from or write to a location outside the cache directory. Keys are
# restricted to letters, digits, dots, underscores and hyphens; every key
# bashio itself uses fits this.
#
# Arguments:
#   $1 Cache key
# ------------------------------------------------------------------------------
function bashio::cache.__valid_key() {
    local key=${1:-}
    local display

    if [[ "${key}" =~ ^[A-Za-z0-9._-]+$ ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    # Sanitize the rejected (untrusted) key before logging it: strip control
    # characters and backslashes so it cannot inject newlines or escape
    # sequences through the log formatter's printf '%b'.
    display=${key//[[:cntrl:]]/?}
    display=${display//\\/?}
    bashio::log.error "Invalid cache key: '${display}'"
    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Check if a cache key exists in the cache
#
# Arguments:
#   $1 Cache key
# ------------------------------------------------------------------------------
function bashio::cache.exists() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::cache.__valid_key "${key}" || return "${__BASHIO_EXIT_NOK}"

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

    bashio::cache.__valid_key "${key}" || return "${__BASHIO_EXIT_NOK}"

    if ! bashio::fs.directory_exists "${__BASHIO_CACHE_DIR}"; then
        # Cached values can contain secrets, so create the directory with an
        # owner-only umask instead of relying on the (predictable) default
        # permissions. A subshell keeps the umask change local to this call.
        (umask 077 && mkdir -p -- "${__BASHIO_CACHE_DIR}") ||
            bashio::exit.nok "Could not create cache folder"
    fi

    # Enforce owner-only access even if the directory already existed, for
    # example one left behind by an older version with broader permissions.
    # Fail hard rather than write secrets into a directory we cannot secure.
    chmod 0700 -- "${__BASHIO_CACHE_DIR}" ||
        bashio::exit.nok "Could not restrict permissions on the cache folder"

    # Remove any existing entry first, so the value is always written to a
    # freshly created file instead of inheriting a permissive mode (or
    # following a symlink) from a file left behind by an older version. If the
    # removal fails, abort rather than write into an unknown target.
    if ! rm -f -- "${__BASHIO_CACHE_DIR}/${key}.cache"; then
        bashio::log.warning "An error occurred while storing ${key} to cache"
        return "${__BASHIO_EXIT_NOK}"
    fi

    # Write under a tight umask so the cache file (which can hold secrets) is
    # created owner-only instead of with the ambient umask.
    if ! (umask 077 && printf "%s" "$value" >"${__BASHIO_CACHE_DIR}/${key}.cache"); then
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

    bashio::cache.__valid_key "${key}" || return "${__BASHIO_EXIT_NOK}"

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
