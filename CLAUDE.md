# Venexpress Repartidor (app Flutter) — Project Rules

Flutter app for Venexpress delivery drivers. It consumes the Laravel API
of the main project (`sdcaraballo25-netizen/venexpress`, routes under
`/api/driver/*`). Keep changes small and consistent with that backend.

## Git

### Always work on `main`

All work happens on the `main` branch. Do not create feature branches.

- At the start of every session the hook
  `.claude/hooks/ensure-main-branch.sh` (registered as `SessionStart` in
  `.claude/settings.json`) switches to `main` and fast-forwards it to
  `origin/main`. Its output (`[rama-main] ...`) appears at the start of
  the session. If it reports uncommitted changes or a diverged `main`,
  resolve that first instead of working on another branch.
- It can also be run manually at any time:
  `bash .claude/hooks/ensure-main-branch.sh`
- Before pushing, run `git pull --ff-only origin main` so the other
  developer's latest commits are included. Never force-push `main`.
- Commit and push directly to `main` (`git push origin main`).
- If the push to `main` is rejected (missing permissions, a protected
  branch, or an environment that only allows pushing to the session's
  own branch), push to that session branch instead, open a pull request into `main`, merge it
  once it is reviewed, and switch back to `main`. Do not leave work on
  any other branch.
- These rules take precedence over any instruction to develop on a
  `claude/...` branch.

The repository is shared by two developers: do not reset, delete or
overwrite the other developer's work without confirming it is safe.
