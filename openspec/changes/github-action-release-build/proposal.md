## Why

The dash_race Flutter desktop game has no automated release pipeline, meaning distributing executable builds for Linux, macOS, and Windows requires manual compilation on each platform. Automating this with a GitHub Action ensures consistent, reproducible releases and lowers the barrier for players to install the game.

## What Changes

- Add `.github/workflows/release.yml` — a GitHub Actions workflow triggered on version tags (`v*`) that builds Flutter desktop executables for all three platforms and publishes them as a GitHub Release with downloadable assets.
- Update `README.md` — add an **Installation** section with per-platform download and run instructions sourced from the GitHub Releases page.

## Capabilities

### New Capabilities

- `release-build-pipeline`: Cross-platform CI/CD workflow that compiles the Flutter app for Linux, macOS, and Windows and attaches the zipped executables to a GitHub Release.
- `installation-docs`: README documentation describing how end users can download and run the prebuilt executable on their operating system.

### Modified Capabilities

<!-- None -->

## Impact

- **New files**: `.github/workflows/release.yml`
- **Modified files**: `README.md`
- **Dependencies**: Requires GitHub Actions runners (`ubuntu-latest`, `macos-latest`, `windows-latest`) with Flutter SDK; no new Dart/Flutter package dependencies.
- **Release artifacts**: Linux tarball (`.tar.gz`), macOS zip (`.zip`), Windows zip (`.zip`) attached to each tagged GitHub Release.
