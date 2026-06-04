#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/repositories.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::repositories` fetcher, its default-filter logic, jq filtering, and
# caching run. The cache is pointed at a per-test temporary directory so tests
# stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::repositories - listing all repositories (no slug)
#
# With no slug, no cache key, and no filter, it must fetch the list endpoint
# and default to the '.[].slug' filter and the 'repositories.list' cache key.
# ------------------------------------------------------------------------------

@test "repositories without arguments lists all repository slugs" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '[{"slug":"core"},{"slug":"local"}]'
    }
    run bashio::repositories
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /store/repositories false" ]
    [ "${output}" = "$(printf 'core\nlocal')" ]
}

@test "repositories without arguments caches the list under repositories.list" {
    bashio::api.supervisor() {
        printf '%s' '[{"slug":"core"},{"slug":"local"}]'
    }
    run bashio::repositories
    [ "${status}" -eq 0 ]
    run bashio::cache.get 'repositories.list'
    [ "${output}" = "$(printf 'core\nlocal')" ]
}

@test "repositories without arguments caches the raw info under repositories.info" {
    bashio::api.supervisor() {
        printf '%s' '[{"slug":"core"}]'
    }
    run bashio::repositories
    [ "${status}" -eq 0 ]
    run bashio::cache.get 'repositories.info'
    [ "${output}" = '[{"slug":"core"}]' ]
}

@test "repositories without arguments reuses the repositories.list cache" {
    bashio::cache.set 'repositories.list' "$(printf 'cached1\ncached2')"
    bashio::api.supervisor() { return 1; }
    run bashio::repositories
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf 'cached1\ncached2')" ]
}

@test "repositories without arguments reuses cached repositories.info" {
    bashio::cache.set 'repositories.info' '[{"slug":"fromcache"}]'
    bashio::api.supervisor() { return 1; }
    run bashio::repositories
    [ "${status}" -eq 0 ]
    [ "${output}" = "fromcache" ]
}

@test "repositories list propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::repositories
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::repositories - a single repository (slug given)
#
# With a slug and no filter, it must fetch the per-repository endpoint and
# default to the '.slug' filter (no list cache key).
# ------------------------------------------------------------------------------

@test "repositories with a slug fetches the per-repository endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repositories "core"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /store/repositories/core false" ]
    [ "${output}" = "core" ]
}

@test "repositories with a slug caches the raw info per slug" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repositories "core"
    [ "${status}" -eq 0 ]
    run bashio::cache.get 'repositories.core.info'
    [ "${output}" = '{"slug":"core","name":"Official"}' ]
}

@test "repositories with a slug reuses the cached per-slug info" {
    bashio::cache.set 'repositories.core.info' '{"slug":"core","name":"Cached"}'
    bashio::api.supervisor() { return 1; }
    run bashio::repositories "core" false '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Cached" ]
}

@test "repositories with a slug propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::repositories "core"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::repositories - explicit cache key and filter handling
# ------------------------------------------------------------------------------

@test "repositories returns a value cached under an explicit cache key" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'repositories.core.name' 'Official add-ons'
    run bashio::repositories "core" 'repositories.core.name' '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Official add-ons" ]
}

@test "repositories stores the filtered response under the explicit cache key" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repositories "core" 'repositories.core.name' '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Official" ]
    run bashio::cache.get 'repositories.core.name'
    [ "${output}" = "Official" ]
}

@test "repositories with filter false returns the raw info unfiltered" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repositories "core" false false
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"slug":"core","name":"Official"}' ]
}

@test "repositories with filter false does not write the explicit cache key" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repositories "core" 'repositories.core.raw' false
    [ "${status}" -eq 0 ]
    run bashio::cache.exists 'repositories.core.raw'
    [ "${status}" -ne 0 ]
}

@test "repositories fails when the jq filter is invalid" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core"}'
    }
    run bashio::repositories "core" false '.['
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Getters: bashio::repository.<field>
# ------------------------------------------------------------------------------

@test "repository.name returns the name field" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repository.name "core"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /store/repositories/core false" ]
    [ "${output}" = "Official" ]
}

@test "repository.name caches under repositories.<slug>.name" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","name":"Official"}'
    }
    run bashio::repository.name "core"
    [ "${status}" -eq 0 ]
    run bashio::cache.get 'repositories.core.name'
    [ "${output}" = "Official" ]
}

@test "repository.source returns the source field" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","source":"git"}'
    }
    run bashio::repository.source "core"
    [ "${status}" -eq 0 ]
    [ "${output}" = "git" ]
}

@test "repository.url returns the url field" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","url":"https://example.com"}'
    }
    run bashio::repository.url "core"
    [ "${status}" -eq 0 ]
    [ "${output}" = "https://example.com" ]
}

@test "repository.maintainer returns the maintainer field" {
    bashio::api.supervisor() {
        printf '%s' '{"slug":"core","maintainer":"Home Assistant"}'
    }
    run bashio::repository.maintainer "core"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Home Assistant" ]
}

@test "repository.name propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::repository.name "core"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::repository.add
# ------------------------------------------------------------------------------

@test "repository.add posts the repository as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::repository.add "https://example.com/repository"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /store/repositories {"repository":"https://example.com/repository"}' ]
}

@test "repository.add propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::repository.add "https://example.com/repository" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::repository.delete
# ------------------------------------------------------------------------------

@test "repository.delete calls the delete endpoint for the slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::repository.delete "core"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /store/repositories/core" ]
}

# ------------------------------------------------------------------------------
# bashio::repository.repair
# ------------------------------------------------------------------------------

@test "repository.repair calls the repair endpoint for the slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::repository.repair "core"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /store/repositories/core/repair" ]
}
