# homebrew-qview

Homebrew tap for [qView](https://github.com/jurplel/qView) — a practical and minimal image viewer.

## Install

```bash
brew tap engels74/qview
brew install --cask qview
```

Or as a one-liner:

```bash
brew install --cask engels74/qview/qview
```

## Update

```bash
brew upgrade --cask qview
```

## Uninstall

```bash
brew uninstall --cask qview
brew untap engels74/qview
```

To also remove application data:

```bash
brew uninstall --cask --zap qview
```

## How It Works

A [GitHub Actions workflow](.github/workflows/update-cask.yml) runs every 6 hours to check for new upstream releases. When a new release is detected, the workflow downloads the macOS `.dmg`, computes its SHA256 checksum, re-hosts it on this repository's [releases](https://github.com/engels74/homebrew-qview/releases), and updates the cask automatically.

Versions match upstream release tags (for example, `7.1`).

On install, the cask runs a `postflight` step that removes the `com.apple.quarantine` attribute from `qView.app`. This works around the Gatekeeper check that caused qView to be disabled in the official Homebrew cask repository, so the app launches without manual `xattr` intervention.

---

This is an unofficial community-maintained tap, not affiliated with the qView developer(s). The upstream app is licensed under [GPL-3.0](https://github.com/jurplel/qView/blob/main/LICENSE); this tap repository is licensed under [AGPL-3.0](LICENSE).
