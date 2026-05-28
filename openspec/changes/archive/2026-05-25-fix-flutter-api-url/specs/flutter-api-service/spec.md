## MODIFIED Requirements

### Requirement: Application Network Target
The application MUST communicate with the deployed production backend to fetch data and stream audio.

#### Scenario: App launches on physical device
- **WHEN** the application starts up and initializes `ApiService`
- **THEN** it MUST use `https://music-vault-767870933282.asia-south1.run.app` as the base URL for all HTTP requests, rather than `localhost`.
