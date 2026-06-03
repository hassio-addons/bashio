# Contributing

First off, thanks for taking the time to contribute! 🎉

Bashio is an active open-source project, and we are always open to people who
want to use the code or contribute to it. The following is a set of guidelines
for contributing; they are not strict rules, so use your best judgment, and feel
free to propose changes to this document in a pull request.

Please note we have a [code of conduct][coc]; please follow it in all your
interactions with the project.

## Reporting bugs and requesting features

- 🐛 **Found a bug?** Open a [bug report][bug-report]. Please search the existing
  [issues][issues] first, as your problem may already be known.
- 💡 **Have an idea or feature request?** Start a [discussion][discussions]
  instead of opening an issue, so the community can weigh in.
- 🔒 **Found a security issue?** Please do not open a public issue; see our
  [security policy][security] for responsible disclosure.

Even better: submit a pull request with a fix or improvement!

## Development

Bashio is a pure Bash function library; every module lives in the
[`lib`](../lib) folder, and each function is documented with a comment block
right above it. We use [prek][prek] to run the same checks locally that run in
our CI.

1. Install [prek][prek].
2. Install the Git hooks so the checks run automatically on every commit:

   ```bash
   prek install
   ```

3. You can run all checks against the whole codebase at any time:

   ```bash
   prek run --all-files
   ```

The following tools run on every pull request and must pass:

- [ShellCheck][shellcheck]: static analysis of the shell scripts.
- [shfmt][shfmt]: shell formatting (`-i 4 -ci`).
- [Prettier][prettier]: formatting of JSON, Markdown, and YAML files.
- [yamllint][yamllint]: linting of YAML files.
- [codespell][codespell]: checks for common misspellings.
- [zizmor][zizmor]: security auditing of the GitHub Actions workflows.

## Tests

The test suite lives in the [`tests`](../tests) folder and uses
[Bats][bats-core]. After installing Bats, run it from the repository root:

```bash
bats tests/
```

Each module has its own `tests/<module>.bats` file; `tests/test_helper.bash`
loads the library so its functions are available to the tests. When you fix a
bug or add a function, please add a test that covers it.

In CI the suite runs under [bashcov][bashcov] and coverage is uploaded to both
[Codecov][codecov] and GitHub's native code coverage.

## Pull request process

1. Search the repository for open or closed [pull requests][prs] that relate to
   your submission, to avoid duplicating effort.
2. Keep your change focused; smaller, well-described pull requests are easier to
   review and merge.
3. Our automation requires every pull request to carry a label describing the
   type of change. You don't need to add this yourself; only maintainers can
   apply labels, and one will be added for you during review. The label check
   may show as failing until then, which is expected.
4. Make sure all checks pass; running `prek run --all-files` helps you catch
   issues before you push.
5. A maintainer will review your pull request and merge it once it is ready.

[bashcov]: https://github.com/infertux/bashcov
[bats-core]: https://github.com/bats-core/bats-core
[bug-report]: https://github.com/hassio-addons/bashio/issues/new?template=bug_report.yml
[codecov]: https://codecov.io/gh/hassio-addons/bashio
[coc]: CODE_OF_CONDUCT.md
[codespell]: https://github.com/codespell-project/codespell
[discussions]: https://github.com/hassio-addons/bashio/discussions
[issues]: https://github.com/hassio-addons/bashio/issues
[prek]: https://github.com/j178/prek
[prettier]: https://prettier.io
[prs]: https://github.com/hassio-addons/bashio/pulls
[security]: SECURITY.md
[shellcheck]: https://www.shellcheck.net
[shfmt]: https://github.com/mvdan/sh
[yamllint]: https://www.yamllint.com
[zizmor]: https://github.com/zizmorcore/zizmor
