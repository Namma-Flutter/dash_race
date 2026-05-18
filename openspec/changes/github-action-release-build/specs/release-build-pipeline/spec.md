## ADDED Requirements

### Requirement: Workflow triggers on version tag push
The release workflow SHALL be triggered automatically when a Git tag matching the pattern `v*.*.*` is pushed to the repository. The workflow SHALL also support manual dispatch via `workflow_dispatch`.

#### Scenario: Tag push triggers release
- **WHEN** a developer pushes a tag matching `v*.*.*` (e.g., `v1.2.0`)
- **THEN** the GitHub Actions release workflow starts within 60 seconds

#### Scenario: Manual dispatch triggers release
- **WHEN** a developer triggers the workflow manually from the GitHub Actions UI
- **THEN** the workflow runs the full build and release sequence

### Requirement: Cross-platform native builds via matrix strategy
The workflow SHALL build the Flutter desktop application natively on Linux, macOS, and Windows using a GitHub Actions matrix. Each platform job SHALL enable the corresponding Flutter desktop target, run `flutter pub get`, and execute `flutter build` in release mode.

#### Scenario: Linux build succeeds
- **WHEN** the workflow runs on `ubuntu-latest`
- **THEN** `flutter build linux --release` completes and produces a binary under `build/linux/x64/release/bundle/`

#### Scenario: macOS build succeeds
- **WHEN** the workflow runs on `macos-latest`
- **THEN** `flutter build macos --release` completes and produces a `.app` bundle under `build/macos/Build/Products/Release/`

#### Scenario: Windows build succeeds
- **WHEN** the workflow runs on `windows-latest`
- **THEN** `flutter build windows --release` completes and produces an executable under `build/windows/x64/runner/Release/`

### Requirement: Build artifacts are archived per platform
Each platform build job SHALL compress its output directory into a platform-appropriate archive and upload it as a GitHub Actions artifact for use by the release job.

#### Scenario: Linux archive created
- **WHEN** the Linux build completes
- **THEN** the bundle directory is compressed into `dash_race-linux.tar.gz` and uploaded as a workflow artifact

#### Scenario: macOS archive created
- **WHEN** the macOS build completes
- **THEN** the `.app` bundle directory is compressed into `dash_race-macos.zip` and uploaded as a workflow artifact

#### Scenario: Windows archive created
- **WHEN** the Windows build completes
- **THEN** the `Release/` output directory is compressed into `dash_race-windows.zip` and uploaded as a workflow artifact

### Requirement: GitHub Release created and assets attached
A dedicated release job SHALL run after all matrix build jobs succeed. It SHALL download all platform archives, create a GitHub Release named after the triggering tag, and attach all three archives as release assets.

#### Scenario: Release created for new tag
- **WHEN** all three platform builds succeed and the release job runs
- **THEN** a GitHub Release is created (or updated) with the tag name and all three archive files attached as downloadable assets

#### Scenario: Release fails if any build fails
- **WHEN** any platform build job fails
- **THEN** the release job does not run and no GitHub Release is created

### Requirement: Flutter SDK and pub cache are cached between runs
The workflow SHALL cache the Flutter SDK installation and the pub package cache to reduce build times on repeated runs.

#### Scenario: Cache hit on repeated run
- **WHEN** the workflow runs and a valid cache exists for the Flutter SDK and pub packages
- **THEN** the setup step restores from cache and skips re-downloading, reducing setup time
