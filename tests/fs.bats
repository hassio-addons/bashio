#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/fs.sh (filesystem helpers).
#
# These use the per-test temporary directory provided by Bats, so they touch
# only throwaway paths.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

@test "fs.directory_exists succeeds for an existing directory" {
    run bashio::fs.directory_exists "${BATS_TEST_TMPDIR}"
    [ "${status}" -eq 0 ]
}

@test "fs.directory_exists fails for a missing directory" {
    run bashio::fs.directory_exists "${BATS_TEST_TMPDIR}/does-not-exist"
    [ "${status}" -ne 0 ]
}

@test "fs.file_exists succeeds for an existing file" {
    touch "${BATS_TEST_TMPDIR}/file"
    run bashio::fs.file_exists "${BATS_TEST_TMPDIR}/file"
    [ "${status}" -eq 0 ]
}

@test "fs.file_exists fails for a missing file" {
    run bashio::fs.file_exists "${BATS_TEST_TMPDIR}/missing"
    [ "${status}" -ne 0 ]
}

@test "fs.file_non_empty fails for an empty file" {
    touch "${BATS_TEST_TMPDIR}/empty"
    run bashio::fs.file_non_empty "${BATS_TEST_TMPDIR}/empty"
    [ "${status}" -ne 0 ]
}

@test "fs.file_non_empty succeeds for a non-empty file" {
    printf 'data' >"${BATS_TEST_TMPDIR}/full"
    run bashio::fs.file_non_empty "${BATS_TEST_TMPDIR}/full"
    [ "${status}" -eq 0 ]
}

@test "fs.device_exists succeeds for a character device" {
    run bashio::fs.device_exists "/dev/null"
    [ "${status}" -eq 0 ]
}

@test "fs.device_exists fails for a regular file" {
    touch "${BATS_TEST_TMPDIR}/regular"
    run bashio::fs.device_exists "${BATS_TEST_TMPDIR}/regular"
    [ "${status}" -ne 0 ]
}

@test "fs.socket_exists fails for a regular file" {
    touch "${BATS_TEST_TMPDIR}/not-a-socket"
    run bashio::fs.socket_exists "${BATS_TEST_TMPDIR}/not-a-socket"
    [ "${status}" -ne 0 ]
}
