# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Unofficial Homebrew tap that distributes [qView](https://github.com/jurplel/qView), a minimal macOS image viewer. The single deliverable is the cask `Casks/qview.rb`. The tap exists to work around the Gatekeeper quarantine issue that disabled qView in the official Homebrew cask repo; on install it strips `com.apple.quarantine` via a `postflight` step.

## Self-hosting model (read first)

The cask does **not** download from upstream. It pulls a re-hosted DMG from this repo's own rolling `latest` GitHub release:

```ruby
url "https://github.com/engels74/homebrew-qview/releases/download/latest/qView-#{version}.dmg"
```

`.github/workflows/update-cask.yml` (every 6h) detects a new `jurplel/qView` release, downloads the upstream `qView-<version>.dmg`, computes its SHA256, uploads it to this repo's `latest` release, then rewrites `version` and `sha256` in `Casks/qview.rb` and commits. The cask version always equals the upstream tag with any leading `v` stripped (e.g. `7.1`).

## Commands

The README install/tap commands are the user-facing surface:

```bash
brew tap engels74/qview                 # add the tap
brew install --cask qview               # install
brew upgrade --cask qview               # update
```

Validate cask edits locally with standard Homebrew tooling (not repo-configured, but the canonical check for casks; requires Homebrew on macOS):

```bash
brew style Casks/qview.rb               # RuboCop-based style/lint
brew audit --cask Casks/qview.rb        # cask correctness audit
```

There is no build step, test suite, or repo-defined linter.

## Architecture and boundaries

- `Casks/qview.rb` — the only cask. Lines 1–2 are a sentinel comment: `version` and `sha256` are machine-managed.
- `.github/workflows/update-cask.yml` — the update pipeline. `update` job: fetch upstream release, validate tag against `^v?[0-9]+\.[0-9]+(\.[0-9]+)?$`, match the **exact** asset `qView-<version>.dmg` (never the `-legacy` DMG), upload to the `latest` release, `sed`-patch the cask, commit/push. `virustotal-scan` job runs only when `VT_API_KEY` is set and an update occurred.
- `.github/workflows/immortality.yml` + `gh-workflow-immortality.sh` — monthly keepalive that force-re-enables scheduled workflows so GitHub's 60-day inactivity suspension never disables the updater. Needs `secrets.PERSONAL_TOKEN`. The shell script is a vendored third-party tool (bash-only).
- `renovate.json` — automerges minor/patch/digest GitHub Actions bumps; major action bumps require review.

## Repository-specific rules and gotchas

- Do not hand-edit the `version` or `sha256` lines in `Casks/qview.rb`. They are rewritten by `update-cask.yml` (lines 295–296); manual changes are overwritten and a mismatched `sha256` breaks installs. To force a version, prefer running/dispatching the workflow.
- If you ever change `version` manually, the matching `qView-<version>.dmg` asset must already exist in this repo's `latest` release, or the cask URL 404s.
- Keep the cask's DMG filename pattern as `qView-#{version}.dmg`; the updater and the URL both depend on this exact name.
- Preserve the `postflight` quarantine-removal block and the `zap trash` paths when editing the cask — they are the reason this tap exists and how it cleans up.
- Secrets the automation relies on: `PERSONAL_TOKEN` (immortality), `VT_API_KEY` (optional VirusTotal scan, gracefully skipped when absent).
