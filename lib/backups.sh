#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is a bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reloads the backups.
# ------------------------------------------------------------------------------
function bashio::backups.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /backups/reload
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Freezes the backups.
#
# Arguments:
#   $1 Timeout (Optional)
# ------------------------------------------------------------------------------
function bashio::backups.freeze() {
    local timeout=${1:-}
    local options=

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${timeout}"; then
        options=$(bashio::var.json timeout "^${timeout}")
    fi
    bashio::api.supervisor POST /backups/freeze "${options}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# End a freeze initiated by bashio::backups.freeze().
# ------------------------------------------------------------------------------
function bashio::backups.thaw() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /backups/thaw
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns or sets the number of days until a backup is considered stale.
#
# Arguments:
#   $1 Set days_until_stale (Optional)
# ------------------------------------------------------------------------------
function bashio::backups.days_until_stale() {
    local days_until_stale=${1:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${days_until_stale}"; then
        days_until_stale=$(bashio::var.json days_until_stale "^${days_until_stale}")
        bashio::api.supervisor POST "/backups/options" "${days_until_stale}"
        bashio::cache.flush_all
    else
        bashio::backups \
            false \
            "backups.days_until_stale" \
            '.days_until_stale // empty'
    fi
}

# ------------------------------------------------------------------------------
# Returns a JSON object with information about backups.
#
# Arguments:
#   $1 Backup slug (optional)
#     (default/empty/'false' for all backups)
#   $2 Cache key to store filtered results in (optional)
#     (default/empty/'false' to cache only unfiltered results)
#   $3 jq filter to apply on the result (optional)
#     (default/empty is '.backups[].slug' with no slug or 'false' with slug)
#     ('false' for no filtering)
# ------------------------------------------------------------------------------
function bashio::backups() {
    local slug=${1:-false}
    local cache_key=${2:-false}
    local filter=${3:-}
    if bashio::var.is_empty "${filter}"; then
        if bashio::var.false "${slug}"; then
            filter='.backups[].slug'
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

    if bashio::var.false "${slug}"; then
        # do not cache backups.info, it is constantly changing
        info=$(bashio::api.supervisor GET "/backups/info" false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get backups from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
    else
        if bashio::cache.exists "backups.${slug}.info"; then
            info=$(bashio::cache.get "backups.${slug}.info")
        else
            info=$(bashio::api.supervisor GET "/backups/${slug}/info" false)
            if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
                bashio::log.error "Failed to get backup info from Supervisor API"
                return "${__BASHIO_EXIT_NOK}"
            fi
            bashio::cache.set "backups.${slug}.info" "${info}"
        fi
    fi

    response="${info}"
    if ! bashio::var.false "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
        if ! bashio::var.false "${cache_key}"; then
            bashio::cache.set "${cache_key}" "${response}"
        fi
    fi

    printf '%s' "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the type of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.type() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.type" '.type'
}

# ------------------------------------------------------------------------------
# Returns the name of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.name() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.name" '.name'
}

# ------------------------------------------------------------------------------
# Returns the date of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.date() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.date" '.date'
}

# ------------------------------------------------------------------------------
# Returns the size of a backup in megabytes.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.size() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.size" '.size'
}

# ------------------------------------------------------------------------------
# Returns the size of a backup in bytes.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.size_bytes() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.size_bytes" '.size_bytes'
}

# ------------------------------------------------------------------------------
# Returns if the backup is protected.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.protected() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.protected" '.protected'
}

# ------------------------------------------------------------------------------
# Returns the location of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.location() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.location" '.location // empty'
}

# ------------------------------------------------------------------------------
# Returns the version of Home Assistant that was in use when the backup is
# created.
#
# Arguments: $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.homeassistant_version() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.homeassistant_version" '.homeassistant // empty'
}

# ------------------------------------------------------------------------------
# Returns the version of Supervisor that was in use when the backup is
# created.
#
# Arguments: $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.supervisor_version() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.supervisor_version" '.supervisor_version // empty'
}

# ------------------------------------------------------------------------------
# Returns the addons of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.addons() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups \
        "${slug}" \
        "backups.${slug}.addons" \
        'if (.addons | length) > 0 then .addons else empty end'
}

# ------------------------------------------------------------------------------
# Returns the repositories of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.repositories() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups \
        "${slug}" \
        "backups.${slug}.repositories" \
        'if (.repositories | length) > 0 then .repositories else empty end'
}

# ------------------------------------------------------------------------------
# Returns the folders of a backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.folders() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups \
        "${slug}" \
        "backups.${slug}.folders" \
        'if (.folders | length) > 0 then .folders else empty end'
}

# ------------------------------------------------------------------------------
# Returns if the Home Assistant database file was excluded from this backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.homeassistant_exclude_database() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups \
        "${slug}" \
        "backups.${slug}.homeassistant_exclude_database" \
        '.homeassistant_exclude_database // false'
}

# ------------------------------------------------------------------------------
# Returns if the backup is compressed.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.compressed() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups "${slug}" "backups.${slug}.compressed" '.compressed'
}

# ------------------------------------------------------------------------------
# Returns if the backup contains homeassistant.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.homeassistant() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::backups \
        false \
        "backups.${slug}.homeassistant" \
        ".backups[] | select(.slug == \"${slug}\") | .content.homeassistant"
}

# ------------------------------------------------------------------------------
# Creates a new full backup.
#
# Arguments:
#   $1 Backup json options, created by eg. bashio::var.json()
# ------------------------------------------------------------------------------
function bashio::backup.new_full() {
    local options=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::api.supervisor POST "/backups/new/full" "${options}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Creates a new partial backup.
#
# Arguments:
#   $1 Backup json options, created by eg. bashio::var.json()
# ------------------------------------------------------------------------------
function bashio::backup.new_partial() {
    local options=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::api.supervisor POST "/backups/new/partial" "${options}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Delete the backup.
#
# Arguments:
#   $1 Backup slug
# ------------------------------------------------------------------------------
function bashio::backup.delete() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::api.supervisor DELETE "/backups/${slug}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Does a full restore of the backup.
#
# Arguments:
#   $1 Backup slug
#   $2 Restore json options, created by eg. bashio::var.json()
# ------------------------------------------------------------------------------
function bashio::backup.restore_full() {
    local slug=${1}
    local options=${2}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::api.supervisor POST "/backups/${slug}/restore/full" "${options}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Does a partial restore of the backup.
#
# Arguments:
#   $1 Backup slug
#   $2 Restore json options, created by eg. bashio::var.json()
# ------------------------------------------------------------------------------
function bashio::backup.restore_partial() {
    local slug=${1}
    local options=${2}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::api.supervisor POST "/backups/${slug}/restore/partial" "${options}"
    bashio::cache.flush_all
}
