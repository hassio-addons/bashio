#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/audio.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# audio fetchers, jq filtering, and caching run. The cache is pointed at a
# per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::audio.update
# ------------------------------------------------------------------------------

@test "audio.update without a version posts to the update endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /audio/update" ]
}

@test "audio.update with a version forwards it as a JSON object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.update "1.2.3"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/update {"version":"1.2.3"}' ]
}

@test "audio.update propagates an API failure with a version" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.update "1.2.3" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "audio.update propagates an API failure without a version" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.update || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.reload (preserved + expanded)
# ------------------------------------------------------------------------------

@test "audio.reload calls the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /audio/reload" ]
}

@test "audio.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.restart
# ------------------------------------------------------------------------------

@test "audio.restart calls the restart endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.restart
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /audio/restart" ]
}

@test "audio.restart propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.restart || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.logs
# ------------------------------------------------------------------------------

@test "audio.logs requests the logs endpoint in raw mode" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.logs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /audio/logs true" ]
}

# ------------------------------------------------------------------------------
# bashio::audio.volume
# ------------------------------------------------------------------------------

@test "audio.volume posts index and volume to the device stream endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.volume "output" "0" "0.5"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/volume/output {"index":0,"volume":0.5}' ]
}

@test "audio.volume targets the application stream when requested" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.volume "input" "2" "1" "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/volume/input/application {"index":2,"volume":1}' ]
}

@test "audio.volume rejects an invalid stream type without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::audio.volume "speaker" "0" "0.5" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "audio.volume rejects a non-numeric index and cannot inject extra keys" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::audio.volume "output" '0,"x":1' "0.5" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "audio.volume rejects a non-numeric volume without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::audio.volume "output" "0" "loud" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "audio.volume propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.volume "output" "0" "0.5" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.mute
# ------------------------------------------------------------------------------

@test "audio.mute posts index and active to the device stream endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.mute "output" "1" "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/mute/output {"index":1,"active":true}' ]
}

@test "audio.mute normalizes the active flag and cannot inject extra keys" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::audio.mute "output" "1" 'true,"x":1'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"index":1,"active":false}' ]
    run jq -e 'has("x")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "audio.mute targets the application stream when requested" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.mute "input" "0" "false" "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/mute/input/application {"index":0,"active":false}' ]
}

@test "audio.mute rejects an invalid stream type without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::audio.mute "speaker" "0" "true" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "audio.mute propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.mute "output" "0" "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.default
# ------------------------------------------------------------------------------

@test "audio.default posts the stream name to the default endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.default "output" "alsa_output.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/default/output {"name":"alsa_output.0"}' ]
}

@test "audio.default escapes the name and cannot inject extra keys" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::audio.default "output" 'x","y":"z'
    [ "${status}" -eq 0 ]
    run jq -e 'has("y")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "audio.default rejects an invalid stream type without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::audio.default "speaker" "x" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "audio.default propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.default "output" "x" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.profile
# ------------------------------------------------------------------------------

@test "audio.profile posts the card and profile name" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::audio.profile "card0" "output:analog-stereo"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /audio/profile {"card":"card0","name":"output:analog-stereo"}' ]
}

@test "audio.profile escapes its arguments and cannot inject extra keys" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::audio.profile 'x","y":"z' "name"
    [ "${status}" -eq 0 ]
    run jq -e 'has("y")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "audio.profile propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.profile "card0" "x" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio (info fetcher)
# ------------------------------------------------------------------------------

@test "audio fetches info from the API and returns the raw object" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"1.0","host":"172.30.32.1"}'
    }
    run bashio::audio
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /audio/info false" ]
    [ "${output}" = '{"version":"1.0","host":"172.30.32.1"}' ]
}

@test "audio caches fetched info and avoids a second API call" {
    echo 0 >"${BATS_TEST_TMPDIR}/api_calls"
    bashio::api.supervisor() {
        calls="$(cat "${BATS_TEST_TMPDIR}/api_calls")"
        echo $((calls + 1)) >"${BATS_TEST_TMPDIR}/api_calls"
        printf '%s' '{"version":"1.0","host":"172.30.32.1"}'
    }

    run bashio::audio
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"version":"1.0","host":"172.30.32.1"}' ]

    run bashio::audio
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"version":"1.0","host":"172.30.32.1"}' ]

    [ "$(cat "${BATS_TEST_TMPDIR}/api_calls")" -eq 1 ]
}

@test "audio applies a jq filter when provided" {
    bashio::api.supervisor() {
        echo "$*" >>"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"1.0","host":"172.30.32.1"}'
    }
    run bashio::audio 'audio.custom' '.host'
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.1" ]

    bashio::api.supervisor() { return 1; }
    run bashio::audio 'audio.custom' '.host'
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.1" ]
    [ "$(wc -l <"${BATS_TEST_TMPDIR}/call")" -eq 1 ]
}

@test "audio serves a cached value without calling the API" {
    bashio::api.supervisor() { return 1; }
    mkdir -p "${__BASHIO_CACHE_DIR}"
    bashio::cache.set 'audio.info' '{"version":"9.9"}'
    run bashio::audio
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"version":"9.9"}' ]
}

@test "audio propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.version
# ------------------------------------------------------------------------------

@test "audio.version extracts the version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","version_latest":"2.0"}'
    }
    run bashio::audio.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.0" ]
}

@test "audio.version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.version || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::audio.version_latest
# ------------------------------------------------------------------------------

@test "audio.version_latest extracts the latest version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","version_latest":"2.0"}'
    }
    run bashio::audio.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.0" ]
}

# ------------------------------------------------------------------------------
# bashio::audio.update_available
# ------------------------------------------------------------------------------

@test "audio.update_available returns the update flag" {
    bashio::api.supervisor() {
        printf '%s' '{"update_available":true}'
    }
    run bashio::audio.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "audio.update_available defaults to false when absent" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0"}'
    }
    run bashio::audio.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

# ------------------------------------------------------------------------------
# bashio::audio.host
# ------------------------------------------------------------------------------

@test "audio.host extracts the host from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"host":"172.30.32.1"}'
    }
    run bashio::audio.host
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.1" ]
}

# ------------------------------------------------------------------------------
# bashio::audio.stats (stats fetcher)
# ------------------------------------------------------------------------------

@test "audio.stats fetches stats from the API and returns the raw object" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5,"memory_usage":1024}'
    }
    run bashio::audio.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /audio/stats false" ]
    [ "${output}" = '{"cpu_percent":1.5,"memory_usage":1024}' ]
}

@test "audio.stats applies a jq filter when provided" {
    calls_file="${BATS_TEST_TMPDIR}/audio_stats_calls"
    printf '%s' 0 >"${calls_file}"
    bashio::api.supervisor() {
        calls="$(cat "${calls_file}")"
        printf '%s' "$((calls + 1))" >"${calls_file}"
        printf '%s' '{"cpu_percent":1.5,"memory_usage":1024}'
    }
    run bashio::audio.stats 'audio.custom' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]
    [ "$(cat "${calls_file}")" -eq 1 ]

    run bashio::audio.stats 'audio.custom' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]
    [ "$(cat "${calls_file}")" -eq 1 ]
}

@test "audio.stats uses cache on repeated calls with the same cache key" {
    calls_file="${BATS_TEST_TMPDIR}/stats_calls"
    printf '0' >"${calls_file}"

    bashio::api.supervisor() {
        calls="$(cat "${calls_file}")"
        calls="$((calls + 1))"
        printf '%s' "${calls}" >"${calls_file}"
        printf '%s' '{"cpu_percent":1.5,"memory_usage":1024}'
    }

    run bashio::audio.stats 'audio.stats.cache' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]

    run bashio::audio.stats 'audio.stats.cache' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]
    [ "$(cat "${calls_file}")" = "1" ]
}

@test "audio.stats propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::audio.stats || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# stats accessors
# ------------------------------------------------------------------------------

@test "audio.cpu_percent extracts the cpu_percent stat" {
    bashio::api.supervisor() {
        printf '%s' '{"cpu_percent":2.5,"memory_usage":1,"memory_limit":2,"memory_percent":3,"network_tx":4,"network_rx":5,"blk_read":6,"blk_write":7}'
    }
    run bashio::audio.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.5" ]
}

@test "audio.memory_usage extracts the memory_usage stat" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_usage":1024}'
    }
    run bashio::audio.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "1024" ]
}

@test "audio.memory_limit extracts the memory_limit stat" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_limit":2048}'
    }
    run bashio::audio.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}

@test "audio.memory_percent extracts the memory_percent stat" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_percent":42}'
    }
    run bashio::audio.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
}

@test "audio.network_tx extracts the network_tx stat" {
    bashio::api.supervisor() {
        printf '%s' '{"network_tx":100}'
    }
    run bashio::audio.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

@test "audio.network_rx extracts the network_rx stat" {
    bashio::api.supervisor() {
        printf '%s' '{"network_rx":200}'
    }
    run bashio::audio.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "200" ]
}

@test "audio.blk_read extracts the blk_read stat" {
    bashio::api.supervisor() {
        printf '%s' '{"blk_read":300}'
    }
    run bashio::audio.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "300" ]
}

@test "audio.blk_write extracts the blk_write stat" {
    bashio::api.supervisor() {
        printf '%s' '{"blk_write":400}'
    }
    run bashio::audio.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "400" ]
}
