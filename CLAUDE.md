# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A single-cask Homebrew tap for [qView](https://github.com/jurplel/qView). There is no application source, build system, test suite, linter, or formatter configured. Every file is either the cask definition, the GitHub Actions automation that maintains it, or vendored third-party shell. Do not look for `npm test`-style validation — it does not exist.

## Architecture Overview

Three moving parts:

- `Casks/qview.rb` — the cask. Its `url` points at **this repository's** rolling `latest` release, not at upstream qView. DMGs are downloaded from upstream and re-hosted here.
- `.github/workflows/update-cask.yml` — the pipeline that keeps the cask file and the rolling release in sync. Runs on `cron: "0 */6 * * *"` and `workflow_dispatch`.
- `gh-workflow-immortality.sh` + `.github/workflows/immortality.yml` — monthly keepalive (`0 2 1 * *`) so GitHub does not disable the cron trigger on a low-activity repo.

The `update` job in `update-cask.yml` runs in this order:

1. Fetch `jurplel/qView`'s latest release. A 404 skips the run; any other non-2xx fails loudly.
2. Reject any tag not matching `^v?[0-9]+\.[0-9]+(\.[0-9]+)?$`, then require an asset named exactly `qView-<version>.dmg` whose download URL is exactly `https://github.com/jurplel/qView/releases/download/<tag>/<asset>`. This deliberately excludes `qView-<ver>-legacy.dmg` and blocks untrusted release metadata from reaching later shell steps.
3. Set `needed=true` if the cask version differs **or** the rolling `latest` release is missing **or** it lacks the expected DMG asset.
4. Download the DMG, `sha256sum` it, upload to the `latest` release (created with `--latest=false`), rewrite `version` and `sha256` in the cask via `sed`, commit as `github-actions[bot]`, push to `main`.
5. The dependent `virustotal-scan` job runs only when `needs.update.outputs.updated == 'true'` and only if `secrets.VT_API_KEY` is set; it appends a report table to the release notes.

## Essential Commands

```bash
# Trigger the update pipeline instead of waiting for the 6-hour cron
gh workflow run update-cask.yml --repo engels74/homebrew-qview

# Read the version the cask currently pins (the same expression the workflow uses)
grep -E '^\s*version\s+"' Casks/qview.rb

# End-to-end verification of a published change
brew install --cask engels74/qview/qview
```

The keepalive script is only ever invoked the way `immortality.yml` invokes it — with `GITHUB_TOKEN` sourced from `secrets.PERSONAL_TOKEN` (not `github.token`, which cannot re-enable workflows) and `REPOS` set:

```bash
GITHUB_TOKEN=… REPOS=engels74/homebrew-qview bash ./gh-workflow-immortality.sh
```

## Implementation Decisions

| Situation | Preferred approach | Avoid |
|---|---|---|
| Cask is behind upstream qView | `gh workflow run update-cask.yml` and let it re-host, rewrite, and push | Hand-editing `version`/`sha256` in `Casks/qview.rb` |
| A GitHub Action needs a newer version | Let Renovate open the PR; non-major action bumps automerge per `renovate.json` | Manual bumps in workflow YAML |
| Changing how releases or assets are produced | Edit the `update` job in `.github/workflows/update-cask.yml` | Editing `gh-workflow-immortality.sh`, which is vendored |

## Critical Gotchas

- **The `sed` rewrites are anchored to exact formatting.** `update-cask.yml` uses `s/^\(  version \)".*"/…/` and `s/^\(  sha256 \)".*"/…/`. Both lines must keep exactly two leading spaces with the quoted value on the same line. Reformatting them breaks auto-update *silently*: `sed` still exits 0, the commit step reports "No cask file changes to commit", and the rolling release ends up ahead of the cask.
- **`version` and `sha256` must always move together.** The checksum belongs to the DMG attached to this repo's `latest` release. Note that the upload step leaves an existing asset in place rather than clobbering it when a file of the same name already exists, so an upstream re-release under the same tag can desynchronize the two. If you ever correct these by hand, re-download the asset from `engels74/homebrew-qview/releases/download/latest/` and hash that.
- **The `postflight` xattr step is the reason this tap exists.** It strips `com.apple.quarantine` from `qView.app` to work around the Gatekeeper failure that got qView disabled in homebrew-cask. Do not remove or make it `must_succeed: true` — the whole point is a launchable app without manual `xattr` intervention.
- **`gh-workflow-immortality.sh` is vendored MIT third-party code** (Daniel Rudolf, v1.1.1) inside an AGPL-3.0 repository. Update it by re-vendoring upstream, not by patching in place. Its header sends the reader to `LICENSE` for the MIT text, but `LICENSE` holds this repository's AGPL-3.0 text; the header also gives the canonical MIT URL, so leave the notice alone rather than editing it out.
- **`renovate.json`'s `gitIgnoredAuthors` lists the exact bot identities** used by the update workflow (`41898282+github-actions[bot]@…`) and the fleet bot. If you change the workflow's `git config user.email`, update `gitIgnoredAuthors` in the same change or Renovate will start treating automated cask commits as human edits.

## Canonical Pattern

Cask changes go in `Casks/qview.rb`. The postflight block is the established shape for anything that must run against the installed app:

```ruby
postflight do
  app_path = File.join(appdir, "qView.app")

  ohai "Removing quarantine attribute from #{app_path}"
  system_command "/usr/bin/xattr",
                 args:         ["-r", "-d", "com.apple.quarantine", app_path],
                 sudo:         false,
                 must_succeed: false
end
```

Use `system_command` with `sudo: false`, and keep `must_succeed: false` for best-effort cleanup so a fresh install never aborts on an app that had no quarantine flag.

## Additional Documentation

- `README.md` — Read before changing install instructions, the described update cadence, or the licensing note; it is the only user-facing description of the re-hosting pipeline and must stay consistent with `update-cask.yml`.
- `.github/workflows/update-cask.yml` — Read in full before touching versioning, asset naming, release notes, or the cask rewrite; the validation guards there are intentional and load-bearing.
