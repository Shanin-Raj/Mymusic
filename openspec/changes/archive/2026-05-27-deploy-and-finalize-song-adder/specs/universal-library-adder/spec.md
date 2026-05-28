## MODIFIED Requirements

### Requirement: Platform-Aware Backend Downloader
The backend downloader and sync system MUST dynamically identify the operating system environment at runtime and execute the correct python binary command (`python` on Windows and `python3` on Linux/macOS) when spawning sub-processes to run yt-dlp metadata extraction or audio downloading. Additionally, the backend MUST instantiate a fresh `TelegramClient` session for every upload or deletion, and explicitly disconnect and destroy all connection resources inside a `finally` block to prevent socket leakage and timeouts under serverless CPU suspension on Cloud Run.

#### Scenario: Running downloader on Windows local development
- **WHEN** the backend receives an add song sync request on a Windows system
- **THEN** it executes yt-dlp by spawning the local `python` command, successfully completing the extraction and downloading pipeline with zero crashes

#### Scenario: Running downloader on Linux production Cloud Run
- **WHEN** the backend receives an add song sync request on a Linux system
- **THEN** it executes yt-dlp by spawning `python3`, ensuring full cloud environment compatibility

#### Scenario: Backend Telegram client connection lifecycle
- **WHEN** the backend uploads a song or deletes a song from the Telegram channel
- **THEN** it connects a fresh, short-lived socket, executes the transaction, and explicitly disconnects and destroys the socket cleanly immediately afterwards
