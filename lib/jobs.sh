#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is a bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reset job manager.
# ------------------------------------------------------------------------------
function bashio::jobs.reset() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /jobs/reset
    if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
        bashio::log.error "Failed to access jobs on Supervisor API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    bashio::cache.flush_all
    return "${__BASHIO_EXIT_OK}"
}


# ------------------------------------------------------------------------------
# Returns a JSON object with information about jobs.
#
# Arguments:
#   $1 Job uuid (optional)
#     (default/empty/'false' for all jobs)
#   $2 Cache key to store filtered results in (optional)
#     (default/empty/'false' to cache only unfiltered results)
#   $3 jq filter to apply on the result (optional)
#     (default/empty is '.jobs[].uuid' with no uuid or 'false' with uuid)
#     ('false' for no filtering)
# ------------------------------------------------------------------------------
function bashio::jobs() {
    local uuid=${1:-false}
    local cache_key=${2:-false}
    local filter=${3:-}
    if bashio::var.is_empty "${filter}"; then
        if bashio::var.false "${uuid}"; then
            filter='.jobs[].uuid'
        else
            filter='false'
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

    if bashio::var.false "${uuid}"; then
        # do not cache jobs.info, it is constantly changing
        info=$(bashio::api.supervisor GET "/jobs/info" false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get jobs from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
    else
        # do not cache jobs.<uuid>.info, it is constantly changing
        info=$(bashio::api.supervisor GET "/jobs/${uuid}" false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get job info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
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
# Returns the name of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.name() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" "jobs.${uuid}.name" '.name'
}

# ------------------------------------------------------------------------------
# Returns the reference of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.reference() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" "jobs.${uuid}.reference" '.reference // empty'
}

# ------------------------------------------------------------------------------
# Returns the progress of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.progress() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" false 'if(.progress != null) then .progress else empty end'
}

# ------------------------------------------------------------------------------
# Returns the stage of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.stage() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" false '.stage // empty'
}

# ------------------------------------------------------------------------------
# Returns the done of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.done() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" false '.done'
}

# ------------------------------------------------------------------------------
# Returns the created of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.created() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" "jobs.${uuid}.created" '.created'
}

# ------------------------------------------------------------------------------
# Returns the child_jobs of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.child_jobs() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" false 'if (.child_jobs | length) > 0 then .child_jobs else empty end'
}

# ------------------------------------------------------------------------------
# Returns the errors of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.errors() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" false 'if (.errors | length) > 0 then .errors else empty end'
}

# ------------------------------------------------------------------------------
# Returns the extra of a job.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.extra() {
    local uuid=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::jobs "${uuid}" false '.extra // empty'
}


# ------------------------------------------------------------------------------
# Removes a completed job from Supervisor cache.
#
# Arguments:
#   $1 Job uuid
# ------------------------------------------------------------------------------
function bashio::job.delete() {
    local uuid=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::api.supervisor "DELETE" "/jobs/${uuid}"
    if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
        bashio::log.error "Failed to access job on Supervisor API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    bashio::cache.flush_all
    return "${__BASHIO_EXIT_OK}"
}
