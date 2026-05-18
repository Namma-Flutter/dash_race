## ADDED Requirements

### Requirement: README contains an Installation section
The `README.md` SHALL include a dedicated **Installation** section that explains how to download and run the prebuilt executable for each supported platform (Linux, macOS, Windows). The section SHALL appear before any development/build-from-source instructions.

#### Scenario: Installation section is present in README
- **WHEN** a user opens `README.md`
- **THEN** they can find an "Installation" section with per-platform download and run instructions

### Requirement: Linux installation instructions are documented
The Installation section SHALL provide step-by-step instructions for Linux users to download the `.tar.gz` release asset, extract it, and run the executable.

#### Scenario: Linux user can follow instructions end-to-end
- **WHEN** a Linux user follows the documented steps
- **THEN** they can download `dash_race-linux.tar.gz` from the GitHub Releases page, extract it, and launch the game binary

### Requirement: macOS installation instructions include Gatekeeper bypass
The Installation section SHALL provide macOS-specific instructions that cover downloading `dash_race-macos.zip`, extracting the `.app`, and bypassing macOS Gatekeeper for unsigned binaries (right-click → Open, or `xattr -cr` command).

#### Scenario: macOS user is informed about Gatekeeper
- **WHEN** a macOS user follows the documented steps
- **THEN** they are made aware that macOS will initially block the app and are given the steps to allow it to run

#### Scenario: macOS user can launch the app
- **WHEN** a macOS user applies the documented Gatekeeper bypass
- **THEN** the `.app` launches successfully

### Requirement: Windows installation instructions are documented
The Installation section SHALL provide step-by-step instructions for Windows users to download `dash_race-windows.zip`, extract it, and run the `.exe` directly (no installer required).

#### Scenario: Windows user can follow instructions end-to-end
- **WHEN** a Windows user follows the documented steps
- **THEN** they can download and extract `dash_race-windows.zip` and run `dash_race.exe` without installing additional software

### Requirement: README links to the GitHub Releases page
The Installation section SHALL include a direct link to the repository's GitHub Releases page so users can find the latest version.

#### Scenario: Releases page link is present
- **WHEN** a user reads the Installation section
- **THEN** they can click a link that navigates to the GitHub Releases page for the repository
