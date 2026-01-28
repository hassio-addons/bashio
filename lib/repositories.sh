#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is a bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with information about repositories.
#
# Arguments:
#   $1 Repository slug (optional)
#     (default/empty/'false' for all repositories)
#   $2 Cache key to store filtered results in (optional)
#     (default/empty/'false' to cache only unfiltered results)
#   $3 jq filter to apply on the result (optional)
#     (default/empty is '.[].slug' with no slug or '.slug' with slug)
#     ('false' for no filtering)
# ------------------------------------------------------------------------------
function bashio::repositories() {
    local slug=${1:-false}
    local cache_key=${2:-false}
    local filter=${3:-}
    if bashio::var.is_empty "${filter}"; then
        if bashio::var.false "${slug}"; then
            filter='.[].slug'
            if bashio::var.false "${cache_key}"; then
                cache_key="repositories.list"
            fi
        else
            filter='.slug'
        fi
    fi
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if ! bashio::var.false "${cache_key}" && \
        bashio::cache.exists "${cache_key}"
    then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::var.false "${slug}"; then
        if bashio::cache.exists "repositories.info"; then
            info=$(bashio::cache.get 'repositories.info')
        else
            info=$(bashio::api.supervisor GET "/store/repositories" false)
            if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
                bashio::log.error "Failed to get repositories from Supervisor API"
                return "${__BASHIO_EXIT_NOK}"
            fi
            bashio::cache.set "repositories.info" "${info}"
        fi
    else
        if bashio::cache.exists "repositories.${slug}.info"; then
            info=$(bashio::cache.get "repositories.${slug}.info")
        else
            info=$(bashio::api.supervisor GET "/store/repositories/${slug}" false)
            if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
                bashio::log.error "Failed to get repository info from Supervisor API"
                return "${__BASHIO_EXIT_NOK}"
            fi
            bashio::cache.set "repositories.${slug}.info" "${info}"
        fi
    fi

    response="${info}"
    if ! bashio::var.false "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if ! bashio::var.false "${cache_key}"; then
            bashio::cache.set "${cache_key}" "${response}"
        fi
    fi

    printf '%s' "${response}"

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

# ------------------------------------------------------------------------------
# Add an addon repository to the store.
#
# Arguments:
#   $1 URL of the addon repository to add to the store.
# ------------------------------------------------------------------------------
function bashio::repository.add() {
    local repository=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    repository=$(bashio::var.json repository "${repository}")
    bashio::api.supervisor POST "/store/repositories" "${repository}"
    if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
        bashio::log.error "Failed to access repository on Supervisor API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    bashio::cache.flush_all
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Remove an unused addon repository from the store.
#
# Arguments:
#   $1 Repository slug
# ------------------------------------------------------------------------------
function bashio::repository.delete() {
    local slug=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::api.supervisor "DELETE" "/store/repositories/${slug}"
    if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
        bashio::log.error "Failed to access repository on Supervisor API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    bashio::cache.flush_all
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Repair/reset an addon repository in the store that is missing or showing incorrect information.
#
# Arguments:
#   $1 Repository slug
# ------------------------------------------------------------------------------
function bashio::repository.repair() {
    local slug=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::api.supervisor "POST" "/store/repositories/${slug}/repair"
    if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
        bashio::log.error "Failed to access repository on Supervisor API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    bashio::cache.flush_all
    return "${__BASHIO_EXIT_OK}"
}
