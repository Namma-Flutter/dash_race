## 1. GitHub Actions Workflow

- [x] 1.1 Create `.github/workflows/release.yml` with trigger on `push` to `v*.*.*` tags and `workflow_dispatch`
- [x] 1.2 Add a `build` matrix job with `os: [ubuntu-latest, macos-latest, windows-latest]`
- [x] 1.3 Add `subosito/flutter-action` step with `channel: stable` and pub cache enabled
- [x] 1.4 Add `flutter config --enable-<platform>-desktop` step per matrix OS
- [x] 1.5 Add `flutter pub get` step
- [x] 1.6 Add `flutter build <platform> --release` step per matrix OS
- [x] 1.7 Add archive step: Linux → `tar -czf dash_race-linux.tar.gz` of bundle dir
- [x] 1.8 Add archive step: macOS → `zip -r dash_race-macos.zip` of `.app` bundle
- [x] 1.9 Add archive step: Windows → `Compress-Archive` of Release dir to `dash_race-windows.zip`
- [x] 1.10 Add `actions/upload-artifact` step in each matrix leg to upload the platform archive
- [x] 1.11 Add a `release` job that `needs: [build]` and runs on `ubuntu-latest`
- [x] 1.12 Add `actions/download-artifact` step in the release job to fetch all three archives
- [x] 1.13 Add `softprops/action-gh-release` step to create the GitHub Release and attach all three archives using `GITHUB_TOKEN`

## 2. README Installation Docs

- [x] 2.1 Add an **Installation** section to `README.md` above any build-from-source instructions
- [x] 2.2 Add a link to the GitHub Releases page in the Installation section
- [x] 2.3 Write Linux instructions: download `dash_race-linux.tar.gz`, extract with `tar`, run the binary
- [x] 2.4 Write macOS instructions: download `dash_race-macos.zip`, extract, right-click → Open (or `xattr -cr dash_race.app && open dash_race.app`) to bypass Gatekeeper
- [x] 2.5 Write Windows instructions: download `dash_race-windows.zip`, extract, run `dash_race.exe`

## 3. Validation

- [ ] 3.1 Push a test tag (e.g., `v1.0.0`) and verify all three platform build jobs pass
- [ ] 3.2 Verify the GitHub Release is created and all three archive assets are attached
- [ ] 3.3 Download and extract each archive on its target OS and confirm the game launches
- [x] 3.4 Review the README Installation section for clarity and accuracy
