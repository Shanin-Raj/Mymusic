## ADDED Requirements

### Requirement: Platform-Aware Backend Downloader
The backend downloader system MUST dynamically identify the operating system environment at runtime and execute the correct python binary command (`python` on Windows and `python3` on Linux/macOS) when spawning sub-processes to run yt-dlp metadata extraction or audio downloading, preventing command execution crashes (such as Exit Code 1 / Status 500).

#### Scenario: Running downloader on Windows local development
- **WHEN** the backend receives an add song sync request on a Windows system
- **THEN** it executes yt-dlp by spawning the local `python` command, successfully completing the extraction and downloading pipeline with zero crashes

#### Scenario: Running downloader on Linux production Cloud Run
- **WHEN** the backend receives an add song sync request on a Linux system
- **THEN** it executes yt-dlp by spawning `python3`, ensuring full cloud environment compatibility

### Requirement: Highly Decoupled Universal Adder Dialog
The system SHALL provide a fully self-contained, isolated stateful modal dialog `UniversalAdderDialog` in the UI to sync songs using Spotify/YouTube Music links or typing manual metadata. If requested, this dialog MUST be completely removable from the application by simply deleting the AppBar `+` icon or deleting the dialog class itself, with absolutely zero impact or side-effects on other library features.

#### Scenario: User clicks Add Song button
- **WHEN** the user selects the "Add Song (Sync Library)" option in the library plus menu
- **THEN** the self-contained `UniversalAdderDialog` opens, offering url inputs, manual entry toggle forms, and a "Sync & Add" submit action

#### Scenario: Add Song successfully finishes
- **WHEN** the sync API call returns success
- **THEN** the dialog displays a beautiful completion check icon, allows the user to click "Close" to dismiss the view, and triggers a reactive refresh of the parent library view
