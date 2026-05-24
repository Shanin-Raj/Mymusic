## ADDED Requirements

### Requirement: Google Cloud Build Support
The system SHALL support container image builds via Google Cloud Build, using the provided Dockerfile.

#### Scenario: Build Container Image
- **WHEN** the deployment script is executed
- **THEN** Google Cloud Build SHALL successfully create a container image in the Artifact Registry

### Requirement: Automated Cloud Run Deployment
The system SHALL support automated deployment to Google Cloud Run, ensuring the service is publicly accessible and configured with correct environment variables.

#### Scenario: Deploy to Cloud Run
- **WHEN** the deploy command is run
- **THEN** the application SHALL be live on a Cloud Run URL and responding to requests
