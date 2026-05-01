## Context

dash_race is a Flutter desktop game targeting Linux, macOS, and Windows. Currently there is no CI/CD pipeline and no automated release mechanism. Developers must manually run `flutter build linux/macos/windows` on each respective platform, then distribute the binaries out-of-band. The project uses standard Flutter tooling with no custom build scripts.

## Goals / Non-Goals

**Goals:**
- Trigger a cross-platform build automatically when a Git tag matching `v*` is pushed.
- Produce compressed, ready-to-run archives for Linux (`.tar.gz`), macOS (`.zip`), and Windows (`.zip`).
- Publish archives as assets on a GitHub Release using the tag as the release name.
- Add concise installation instructions to `README.md` covering all three platforms.

**Non-Goals:**
- Code signing or notarization of macOS/Windows binaries (complex setup, no current requirement).
- App store distribution (Snap, Homebrew, Winget, etc.).
- Automated version bumping or changelog generation.
- Running tests as part of the release workflow (test step can be added separately).

## Decisions

### Decision 1: Matrix strategy for cross-platform builds

Use a GitHub Actions `matrix` with `os: [ubuntu-latest, macos-latest, windows-latest]` so each platform builds natively on the correct runner. Each matrix leg enables the relevant Flutter desktop target, builds the release binary, archives it, and uploads it as a workflow artifact; a final `release` job downloads all artifacts and attaches them to the GitHub Release.

**Alternatives considered:**
- Cross-compilation from a single runner: Flutter desktop builds are not supported cross-platform; each OS must build on its own runner.
- Separate workflow files per platform: More configuration overhead, harder to keep in sync.

### Decision 2: Archive format

- Linux: `.tar.gz` — standard on Linux, preserves file permissions for the ELF executable.
- macOS: `.zip` — `.app` bundles are directory trees; zip is the most portable option without requiring code signing.
- Windows: `.zip` — widely supported on Windows 10+ without extra tooling.

### Decision 3: GitHub Release via `softprops/action-gh-release`

Use the `softprops/action-gh-release` action (widely adopted, minimal config) to create/update the GitHub Release and attach assets in one step. The GITHUB_TOKEN provided automatically by Actions is sufficient for this.

**Alternatives considered:**
- `gh` CLI (`gh release create`): Requires shell scripting to handle OS-specific asset names; more brittle.
- GitHub REST API directly: Verbose and error-prone.

### Decision 4: Workflow trigger

Trigger on `push` to tags matching `v*.*.*` (e.g., `v1.0.0`). This keeps release creation explicit and intentional — no accidental releases from branch pushes.

### Decision 5: Flutter version pinning

Use `subosito/flutter-action` with `channel: stable` without pinning a specific version, so the workflow automatically picks up the latest stable Flutter release. The project's `pubspec.yaml` SDK constraint (`^3.10.4`) guards against incompatible SDK versions at `flutter pub get`.

## Risks / Trade-offs

- **macOS runner build time** → macOS GitHub-hosted runners are slower; builds may take 10–15 min. Mitigation: cache the Flutter SDK and pub packages.
- **No code signing** → macOS Gatekeeper will block the downloaded `.app` on first launch unless the user right-clicks and opens. Mitigation: document the workaround in `README.md`.
- **Windows path length limits** → Flutter build artifacts can have deep paths that exceed Windows 260-char limit. Mitigation: keep repo path short; workflow uses default checkout directory.
- **`pubspec.lock` drift** → If `pubspec.lock` is not committed, `pub get` may resolve different versions between local dev and CI. Mitigation: ensure `pubspec.lock` is committed (it already appears modified in git status).

## Migration Plan

1. Create `.github/workflows/release.yml`.
2. Update `README.md` with installation section.
3. Push a tag `v1.0.0` to trigger the first release and verify all three platform assets are attached.
4. No rollback needed — removing the workflow file stops future releases; existing releases are unaffected.

## Open Questions

- Should the workflow also run on `workflow_dispatch` to allow manual release triggers? (Recommended yes — adds flexibility.)
- Should macOS Gatekeeper bypass steps be documented in README? (Yes — essential for unsigned `.app`.)
