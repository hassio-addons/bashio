#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about repositories.
#
# Arguments:
#   $1 Add-on slug (optional)
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::repositories() {
    local slug=${1:-false}
    local cache_key=${2:-'repositories.list'}
    local filter=${3:-'.repositories[].slug'}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::var.false "${slug}"; then
        if bashio::cache.exists "repositories.list"; then
            info=$(bashio::cache.get 'repositories.list')
        else
            info=$(bashio::api.supervisor GET "/addons" false)
            bashio::cache.set "repositories.list" "${info}"
        fi
    else
        if bashio::cache.exists "repositories.${slug}.info"; then
            info=$(bashio::cache.get "repositories.${slug}.info")
        else
            info=$(bashio::api.supervisor GET "/addons" \
                    false ".repositories[] | select(.slug==\"${slug}\")")
            bashio::cache.set "repositories.${slug}.info" "${info}"
        fi
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
    fi

    bashio::cache.set "${cache_key}" "${response}"
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the name of a repository.
#
# Arguments:
#   $1 Repository slug
# ------------------------------------------------------------------------------
function bashio::repository.name() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::repositories "${slug}" "repositories.${slug}.name" '.name'
}

# ------------------------------------------------------------------------------
# Returns the source of a repository.
#
# Arguments:
#   $1 Repository slug
# ------------------------------------------------------------------------------
function bashio::repository.source() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::repositories "${slug}" "repositories.${slug}.source" '.source'
}

# ------------------------------------------------------------------------------
# Returns the URL of a repository.
#
# Arguments:
#   $1 Repository slug
# ------------------------------------------------------------------------------
function bashio::repository.url() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::repositories "${slug}" "repositories.${slug}.url" '.url'
}

# ------------------------------------------------------------------------------
# Returns the maintainer of a repository.
#
# Arguments:
#   $1 Repository slug
# ------------------------------------------------------------------------------
function bashio::repository.maintainer() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::repositories "${slug}" "repositories.${slug}.maintainer" '.maintainer'
}
