# cloud-migration-readiness Specification

## Purpose
TBD - created by archiving change migrate-and-android-convert. Update Purpose after archive.
## Requirements
### Requirement: Cross-Platform Credential Ingestion
The backend system SHALL prioritize environment-based secret injection for all critical credentials (Firebase, Telegram, Spotify) to ensure compatibility with non-GCP hosts.

#### Scenario: Running on Render
- **WHEN** the container is started with a `FIREBASE_KEY_JSON` environment variable
- **THEN** the application SHALL successfully initialize the Firestore client without requiring a local `firebase-key.json` file

### Requirement: Portable Docker Runtime
The `Dockerfile` SHALL maintain a standard Node.js runtime environment that is deployable to any OCI-compliant container host (Render, Fly.io, etc.).

#### Scenario: Building for Render
- **WHEN** the project is built using a generic Docker engine
- **THEN** it SHALL produce a valid image that runs without Google Cloud Build-specific artifacts

