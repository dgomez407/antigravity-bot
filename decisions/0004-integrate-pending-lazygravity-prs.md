# ADR 0004: Integrate Pending LazyGravity Pull Requests

## Status

Accepted

## Context

The parent repository depends on fixes submitted to upstream LazyGravity that
may remain unmerged for some time. A fresh recursive clone must receive all
required fixes without merging those changes into the fork's default branch or
depending on uncommitted submodule state.

## Decision

Maintain `integration/pending-upstream-prs` in the LazyGravity fork. Build it
from upstream `main`, merge each still-pending pull-request branch with an
explicit merge commit, test the combined result, and push the integration
branch to the fork.

The parent repository pins the exact tested integration commit through its
`vendor/LazyGravity` submodule pointer. Fresh checkouts use:

```bash
git clone --recurse-submodules <parent-repository-url>
```

When upstream accepts a pull request, rebuild the integration branch from the
latest upstream `main`, merge only the remaining pending branches, retest,
force-push with `--force-with-lease`, and update the parent submodule pointer.

## Consequences

- Each upstream pull request remains independently reviewable.
- The fork's default branch remains aligned with upstream.
- Recursive parent-repository clones reproduce the tested combined fixes.
- Rebuilding the integration branch after upstream merges requires updating
  and committing the parent repository's submodule pointer.

