# AGENTS.md

This file provides guidance to AI coding agents when working with code in this
repository.

Single-cask Homebrew tap for [qView](https://github.com/jurplel/qView). No application
source, build system, test suite, linter, or formatter exists — nothing to run locally, and
no CI job validates the cask before it ships. The only end-to-end check is installing on
macOS: `brew install --cask engels74/qview/qview`.

## Pipeline invariants

- `Casks/qview.rb`'s `url` resolves to **this** repo's rolling `latest` release, not to
  upstream. `.github/workflows/update-cask.yml` downloads the upstream DMG, re-hosts it
  here, and pins `sha256` to the re-hosted copy. Don't point `url` at `jurplel/qView`.
- `version` and `sha256` are machine-written. To change them, run the workflow
  (`gh workflow run update-cask.yml --repo engels74/homebrew-qview`) rather than editing by
  hand; if you must hand-edit, hash the DMG from
  `engels74/homebrew-qview/releases/download/latest/`, not the upstream one.
- Those two lines are rewritten by `sed -i "s/^\(  version \)\".*\"/…/"`. Keep exactly two
  leading spaces with the quoted value on the same line. Reformatting them fails
  **silently**: sed exits 0, the commit step reports "No cask file changes to commit", and
  the rolling release drifts ahead of the cask.
- The `postflight` block strips `com.apple.quarantine` from `qView.app` — the reason this
  tap exists apart from homebrew-cask. Keep `must_succeed: false` so installing over an
  app with no quarantine flag doesn't abort.

## Footguns

- **An upstream re-release under an existing tag is never picked up.** The check step sets
  `needed=false` when the cask version matches and the `latest` release already holds
  `qView-<version>.dmg`, and the upload step deliberately leaves a same-named asset in
  place. Recovery: delete that asset from the `latest` release, then re-run the workflow —
  it will re-download, re-hash, and `--clobber`.
- The upstream-asset guards in `update-cask.yml` are load-bearing, not defensive noise: the
  tag regex `^v?[0-9]+\.[0-9]+(\.[0-9]+)?$`, the exact-name match on `qView-<version>.dmg`
  (which excludes `qView-<version>-legacy.dmg`), and the exact-URL match against
  `https://github.com/jurplel/qView/releases/download/<tag>/<asset>`. Relaxing any of them
  lets untrusted upstream release metadata reach later shell steps, or publishes the wrong
  package. Add guards here; don't remove them.
- `renovate.json`'s `gitIgnoredAuthors` hardcodes the workflow's committer identity
  (`41898282+github-actions[bot]@users.noreply.github.com`). If you change
  `git config user.email` in `update-cask.yml`, change it here in the same commit or
  Renovate starts treating automated cask commits as human edits.
- `gh-workflow-immortality.sh` is vendored third-party code (Daniel Rudolf, MIT, v1.1.1)
  inside an AGPL-3.0 repo. Re-vendor from upstream rather than patching in place; note its
  header points at "LICENSE file", which in this repo is the AGPL text, not the MIT one.
- `immortality.yml` runs on `secrets.PERSONAL_TOKEN`, not `github.token` — the default
  token cannot re-enable a workflow GitHub disabled for inactivity. If the update-cask
  6-hour cron silently stops firing, check that secret first.
- The `virustotal-scan` job no-ops when `secrets.VT_API_KEY` is unset. Missing scan results
  in the release notes is expected, not a bug to fix.

## Reference

- `.github/workflows/update-cask.yml` — the whole update pipeline: upstream fetch,
  validation, re-hosting, cask rewrite, push, VirusTotal. Read in full before changing
  versioning, asset naming, release notes, or the cask rewrite.
- `README.md` — user-facing install/update/uninstall commands and the only prose
  description of the re-hosting pipeline. Keep in sync when pipeline behaviour or cadence
  changes.
- `gh-workflow-immortality.sh` — vendored keepalive; its `--help` block documents the env
  vars it reads (`GITHUB_TOKEN`, `REPOS`, and the `*_REPOS` selectors). Read only if the
  keepalive itself misbehaves.
