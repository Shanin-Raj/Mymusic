## ADDED Requirements

### Requirement: Robust Client Initialization
The Telegram client SHALL be initialized with enhanced connection settings to handle network instability. This includes setting `connectionRetries` to a minimum of 10 and implementing a timeout for the initial connection phase.

#### Scenario: Network Instability During Startup
- **WHEN** the server starts and attempts to connect to Telegram
- **THEN** the client SHALL retry the connection up to the configured limit before failing

### Requirement: Automatic Reconnection
The system SHALL detect lost connections to the Telegram MTProto servers and attempt to reconnect automatically without requiring a process restart.

#### Scenario: Connection Lost During Idle
- **WHEN** the client is connected but the network connection is dropped
- **THEN** the GramJS client SHALL automatically attempt to re-establish the session

### Requirement: Error Reporting for Connection Timeouts
The system SHALL specifically catch `ETIMEDOUT` errors and provide a descriptive log entry including the target DC (Data Center) IP address.

#### Scenario: Timeout During File Upload
- **WHEN** a song upload fails due to a network timeout
- **THEN** the system SHALL log the error with the specific DC IP and notify the caller of the failure
