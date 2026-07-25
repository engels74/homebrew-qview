# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Repository contracts

- `Casks/qview.rb` is the only deliverable. Its `version` and `sha256` are owned by
  `.github/workflows/update-cask.yml`; dispatch that workflow rather than hand-editing them.
- The cask installs a versioned asset from this repository's rolling `latest` release, not
  directly from upstream. The updater, release asset, and cask URL must continue to agree on
  the exact name `qView-<version>.dmg`.
- Upstream discovery accepts only `v?MAJOR.MINOR[.PATCH]`, strips the optional `v` for the cask
  version, and requires the exact non-legacy upstream DMG. Preserve all three checks when
  changing release detection.
- Keep the cask's `postflight` quarantine removal when changing installation behavior; it is
  the tap's workaround for Gatekeeper blocking the upstream app.
- `.github/workflows/update-cask.yml` repairs a missing rolling release or missing asset even
  when the cask version is already current. Do not reduce update detection to version comparison.
- The VirusTotal job is optional and skips without `VT_API_KEY`. The monthly keepalive workflow
  is separate and requires `PERSONAL_TOKEN`.

## Verification

There is no repository-configured build, test suite, linter, typechecker, or single-test
command. Treat the GitHub Actions workflows as the executable specification for updater
changes. The vendored keepalive script exposes its checked-in interface with:

```bash
bash ./gh-workflow-immortality.sh --help
```

## Read on demand

- `.github/workflows/update-cask.yml` — complete release mirroring, cask rewrite, commit, and
  VirusTotal pipeline. Read before changing `Casks/qview.rb` release fields or update behavior.
- `.github/workflows/immortality.yml` and `gh-workflow-immortality.sh` — scheduled-workflow
  keepalive. Read only when changing inactivity prevention or its authentication.
- `README.md` — supported user install, upgrade, uninstall, and zap commands. Read when changing
  the tap's user-facing behavior or documentation.
