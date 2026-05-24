## ADDED Requirements

### Requirement: Dynamic Port Binding
The server SHALL listen on the port defined by the `PORT` environment variable, defaulting to 8080 if not provided.

#### Scenario: Startup in Cloud Run
- **WHEN** the container starts with `PORT=8080` environment variable
- **THEN** the server SHALL bind to port 8080 and be accessible to the Cloud Run load balancer
