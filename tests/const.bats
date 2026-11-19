#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/const.sh: the library version stamped in by `git archive`.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

# The export-subst placeholder exactly as it appears in lib/const.sh.
VERSION_PLACEHOLDER="'\$Format:%(describe:tags=true,match=v[0-9]*)\$'"

# Copies the library with the version placeholder replaced by $1 (a quoted
# shell literal, as git archive would leave it) and prints the version and
# User-Agent it reports.
version_from_archive() {
    local lib="${BATS_TEST_TMPDIR}/lib"
    local content
    cp -R "${BASHIO_TEST_ROOT}/lib" "${lib}"
    content=$(<"${BASHIO_TEST_ROOT}/lib/const.sh")
    printf '%s\n' "${content/"${VERSION_PLACEHOLDER}"/"${1}"}" >"${lib}/const.sh"
    # shellcheck disable=SC2016 # expanded by the inner shell, not this one
    bash -c 'source "$1/bashio.sh"; printf "%s|%s" "${__BASHIO_VERSION}" "${__BASHIO_USER_AGENT}"' \
        _ "${lib}"
}

@test "const.sh holds exactly one export-subst placeholder" {
    # export-subst rewrites every placeholder in the file, so a second one would
    # silently change other code in the release tarball.
    run grep -c 'Format:' "${BASHIO_TEST_ROOT}/lib/const.sh"
    [ "${output}" -eq 1 ]
    run grep -cF "${VERSION_PLACEHOLDER}" "${BASHIO_TEST_ROOT}/lib/const.sh"
    [ "${output}" -eq 1 ]
}

@test "const.sh is marked for export-subst" {
    if ! git -C "${BASHIO_TEST_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
        skip "not running from a git checkout"
    fi
    run git -C "${BASHIO_TEST_ROOT}" check-attr export-subst -- lib/const.sh
    [ "${output}" = "lib/const.sh: export-subst: set" ]
}

@test "version is the release tag without its v prefix" {
    run version_from_archive "'v1.2.3'"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.2.3|bashio/1.2.3" ]
}

@test "version keeps the describe suffix for an archive of an untagged commit" {
    run version_from_archive "'v1.2.3-4-gabcdef0'"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.2.3-4-gabcdef0|bashio/1.2.3-4-gabcdef0" ]
}

@test "version is dev when the archive has no tag to describe" {
    run version_from_archive "''"
    [ "${status}" -eq 0 ]
    [ "${output}" = "dev|bashio/dev" ]
}

@test "version is dev in a git checkout" {
    # The placeholder is still unexpanded outside of git archive.
    run version_from_archive "${VERSION_PLACEHOLDER}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "dev|bashio/dev" ]
}
