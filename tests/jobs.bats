#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/jobs.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::jobs` fetcher, jq filtering, and caching run. The cache is pointed at
# a per-test temporary directory so tests stay isolated. The stub records the
# forwarded method/resource/filter to a file so they can be asserted, and can be
# made to fail (return 1) to verify error propagation.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# jobs.reset
# ------------------------------------------------------------------------------

@test "jobs.reset posts to the reset endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::jobs.reset
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /jobs/reset" ]
}

@test "jobs.reset propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::jobs.reset || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::jobs.options
# ------------------------------------------------------------------------------

@test "jobs.options posts the given JSON to the options endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::jobs.options '{"ignore_conditions":["healthy"]}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /jobs/options {"ignore_conditions":["healthy"]}' ]
}

@test "jobs.options propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::jobs.options '{"ignore_conditions":[]}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "jobs.options flushes the cache after a successful set" {
    bashio::cache.set 'some.key' 'stale'
    bashio::api.supervisor() { return 0; }
    run bashio::jobs.options '{"ignore_conditions":[]}'
    [ "${status}" -eq 0 ]
    run bashio::cache.exists 'some.key'
    [ "${status}" -ne 0 ]
}

@test "jobs.options does not log the options payload" {
    # The options object is an opaque caller-provided payload, so it must not
    # reach the trace log. Call directly (not via run) so the captured message
    # survives.
    logged=""
    bashio::log.trace() { logged+=" $*"; }
    bashio::api.supervisor() { return 0; }
    bashio::jobs.options '{"ignore_conditions":["SENTINEL_VALUE"]}'
    [[ "${logged}" != *"SENTINEL_VALUE"* ]]
}

# ------------------------------------------------------------------------------
# jobs (the generic fetcher)
# ------------------------------------------------------------------------------

@test "jobs without a uuid lists all job uuids" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"jobs":[{"uuid":"111"},{"uuid":"222"}]}'
    }
    run bashio::jobs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /jobs/info false" ]
    [ "${lines[0]}" = "111" ]
    [ "${lines[1]}" = "222" ]
}

@test "jobs with a uuid fetches that job from the jobs endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"uuid":"111","name":"backup_manager_full_backup"}'
    }
    run bashio::jobs "111" false '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "backup_manager_full_backup" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /jobs/111 false" ]
}

@test "jobs returns a cached result without calling the API" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    printf '%s' "cached-value" >"${__BASHIO_CACHE_DIR}/some.key.cache"
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::jobs "111" "some.key" '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "jobs stores the filtered result in the cache key" {
    bashio::api.supervisor() { printf '%s' '{"uuid":"111","name":"job"}'; }
    run bashio::jobs "111" "jobs.111.name" '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "job" ]
    [ -f "${__BASHIO_CACHE_DIR}/jobs.111.name.cache" ]
    [ "$(cat "${__BASHIO_CACHE_DIR}/jobs.111.name.cache")" = "job" ]
}

@test "jobs with filter 'false' returns the raw info untouched" {
    bashio::api.supervisor() { printf '%s' '{"uuid":"111"}'; }
    run bashio::jobs "111" false false
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"uuid":"111"}' ]
}

@test "jobs propagates a failure to list all jobs" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::jobs || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "jobs propagates a failure to fetch a single job" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::jobs "111" false '.name' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "jobs fails when the jq filter is invalid" {
    bashio::api.supervisor() { printf '%s' '{"uuid":"111"}'; }
    rc=0
    bashio::jobs "111" false '.[' || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# job.* accessors (uuid, cache key, and filter forwarding)
# ------------------------------------------------------------------------------

@test "job.name returns the job name and caches it" {
    bashio::api.supervisor() {
        echo "$2" >"${BATS_TEST_TMPDIR}/resource"
        printf '%s' '{"name":"backup_manager_full_backup"}'
    }
    run bashio::job.name "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "backup_manager_full_backup" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/resource")" = "/jobs/111" ]
    [ -f "${__BASHIO_CACHE_DIR}/jobs.111.name.cache" ]
}

@test "job.reference returns the reference when present" {
    bashio::api.supervisor() { printf '%s' '{"reference":"core_ssh"}'; }
    run bashio::job.reference "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "core_ssh" ]
}

@test "job.reference returns empty when the reference is null" {
    bashio::api.supervisor() { printf '%s' '{"reference":null}'; }
    run bashio::job.reference "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "job.progress returns the progress when set" {
    bashio::api.supervisor() { printf '%s' '{"progress":42}'; }
    run bashio::job.progress "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
}

@test "job.progress returns empty when progress is null" {
    bashio::api.supervisor() { printf '%s' '{"progress":null}'; }
    run bashio::job.progress "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "job.progress is not cached" {
    bashio::api.supervisor() { printf '%s' '{"progress":42}'; }
    run bashio::job.progress "111"
    [ "${status}" -eq 0 ]
    [ ! -d "${__BASHIO_CACHE_DIR}" ] || [ -z "$(ls -A "${__BASHIO_CACHE_DIR}")" ]
}

@test "job.stage returns the stage when present" {
    bashio::api.supervisor() { printf '%s' '{"stage":"home_assistant"}'; }
    run bashio::job.stage "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "home_assistant" ]
}

@test "job.stage returns empty when the stage is null" {
    bashio::api.supervisor() { printf '%s' '{"stage":null}'; }
    run bashio::job.stage "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "job.done returns the done flag" {
    bashio::api.supervisor() { printf '%s' '{"done":true}'; }
    run bashio::job.done "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "job.created returns the creation timestamp and caches it" {
    bashio::api.supervisor() { printf '%s' '{"created":"2024-01-01T00:00:00Z"}'; }
    run bashio::job.created "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024-01-01T00:00:00Z" ]
    [ -f "${__BASHIO_CACHE_DIR}/jobs.111.created.cache" ]
}

@test "job.child_jobs returns the list when non-empty" {
    bashio::api.supervisor() { printf '%s' '{"child_jobs":[{"uuid":"222"}]}'; }
    run bashio::job.child_jobs "111"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"222"* ]]
}

@test "job.child_jobs returns empty when the list is empty" {
    bashio::api.supervisor() { printf '%s' '{"child_jobs":[]}'; }
    run bashio::job.child_jobs "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "job.errors returns the list when non-empty" {
    bashio::api.supervisor() { printf '%s' '{"errors":[{"type":"BackupError"}]}'; }
    run bashio::job.errors "111"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"BackupError"* ]]
}

@test "job.errors returns empty when the list is empty" {
    bashio::api.supervisor() { printf '%s' '{"errors":[]}'; }
    run bashio::job.errors "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "job.extra returns the metadata when present" {
    bashio::api.supervisor() { printf '%s' '{"extra":{"foo":"bar"}}'; }
    run bashio::job.extra "111"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"bar"* ]]
}

@test "job.extra returns empty when the metadata is null" {
    bashio::api.supervisor() { printf '%s' '{"extra":null}'; }
    run bashio::job.extra "111"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "job.name propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::job.name "111" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "job.progress propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::job.progress "111" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# job.delete
# ------------------------------------------------------------------------------

@test "job.delete deletes the job by uuid" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::job.delete "111"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /jobs/111" ]
}

@test "job.delete propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::job.delete "111" || rc=$?
    [ "${rc}" -ne 0 ]
}
