#!/bin/bash
# Bundle A item 5 (#254): ci-steps.sh prints the run: steps of the jobs a pull request runs, from the workflow the project's ci: line names.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
CS="$PLUGIN/scripts/ci-steps.sh"
cd "$T" || exit 1
mkdir -p .github/workflows docs/agents
cat >.github/workflows/ci.yml <<'Y'
name: ci
on:
  push:
    branches: [main]
  pull_request:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Types
        run: npm run typecheck
      - run: npm run lint
      - name: Several lines
        run: |
          npm ci
          npm test -- --offline
      - name: Folded
        run: >-
          echo one
          two
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
Y
printf 'ci: workflow .github/workflows/ci.yml runs the tests on pull requests (check: `ci`)\n' >docs/agents/factory.md
out="$(bash "$CS" docs/agents/factory.md)"; ck steps-rc 0 "$?"
ck steps-list "npm run typecheck
npm run lint
npm ci; npm test -- --offline
echo one two
./deploy.sh" "$out"
# a workflow that does not run on pull requests prints none
cat >.github/workflows/push.yml <<'Y'
name: push
on: [push]
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: make
Y
printf 'ci: workflow .github/workflows/push.yml runs on push\n' >docs/agents/factory.md
ck push-only-none "none" "$(bash "$CS" docs/agents/factory.md)"
cat >.github/workflows/inline.yml <<'Y'
name: inline
on: [push, pull_request]
jobs:
  j:
    runs-on: ubuntu-latest
    steps:
      - run: make test
Y
printf 'ci: workflow .github/workflows/inline.yml runs make test\n' >docs/agents/factory.md
ck inline-list "make test" "$(bash "$CS" docs/agents/factory.md)"
cat >.github/workflows/pr.yml <<'Y'
name: pr
on: pull_request
jobs:
  j:
    steps:
      - run: make a
Y
printf 'ci: workflow .github/workflows/pr.yml runs make a\n' >docs/agents/factory.md
ck scalar-on "make a" "$(bash "$CS" docs/agents/factory.md)"
# ci: none
printf 'ci: none\n' >docs/agents/factory.md
ck ci-none "none" "$(bash "$CS" docs/agents/factory.md)"
# a workflow path that is missing or leaves .github/workflows is refused
printf 'ci: workflow .github/workflows/missing.yml x\n' >docs/agents/factory.md
bash "$CS" docs/agents/factory.md >/dev/null 2>&1; ck missing-workflow-2 2 "$?"
printf 'ci: workflow ../etc/x.yml x\n' >docs/agents/factory.md
bash "$CS" docs/agents/factory.md >/dev/null 2>&1; ck escape-refused-2 2 "$?"
# this repository's own workflow
printf 'ci: workflow .github/workflows/factory-tests.yml runs `bash tests/run.sh` on pull requests (check: `factory tests (macos)`)\n' >own.md
own="$(cd "$REPO" && bash "$CS" "$T/own.md")"
ck own-has-suite "yes" "$(printf '%s\n' "$own" | grep -qx 'bash tests/run.sh' && echo yes || echo no)"
ck own-has-versions "yes" "$(printf '%s\n' "$own" | grep -q '^bash --version | head -1' && echo yes || echo no)"
# text
has qa-done-ci "$PLUGIN/agents/qa-engineer.md" 'a hand back without them is incomplete'
has qa-done-names-script "$PLUGIN/agents/qa-engineer.md" 'scripts/ci-steps.sh'
has run-roles-names-script "$PLUGIN/references/run-roles.md" 'scripts/ci-steps.sh'
done_
