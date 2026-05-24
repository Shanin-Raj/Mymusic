## Context

The Sonic Vault application needs a reliable cloud hosting solution. Google Cloud Run is chosen for its simplicity, scaling capabilities, and pay-per-use model. The backend requires system-level tools (FFmpeg, Python) which must be included in the container image.

## Goals / Non-Goals

**Goals:**
- Containerize the application using a production-ready `Dockerfile`.
- Set up a deployment flow using Google Cloud Build and Cloud Run.
- Adapt the server to listen on the dynamic `$PORT` provided by Cloud Run.

**Non-Goals:**
- Setting up a fully automated CI/CD pipeline (e.g., GitHub Actions) in this phase.
- Migrating the Firebase database to a different region or project.

## Decisions

### 1. Multi-Stage Docker Build
**Decision:** Use a multi-stage Docker build starting from a Node.js base image, installing system dependencies in the final production stage.
**Rationale:** This keeps the image size smaller and more secure by excluding build-only tools from the final image.
**Alternatives:** Using a monolithic image containing everything, which would be larger and slower to deploy.

### 2. Secret Management via Environment Variables
**Decision:** Pass credentials (API keys, bot tokens) as environment variables to Cloud Run, managed via the Google Cloud Console or `gcloud` CLI.
**Rationale:** This is the most straightforward way to manage secrets in Cloud Run without adding complex code for Cloud Secret Manager integration in the first pass.
**Alternatives:** Integrating the `google-cloud/secret-manager` Node.js SDK, which can be done in a later phase.

### 3. Artifact Registry for Image Storage
**Decision:** Store container images in Google Artifact Registry.
**Rationale:** It is the modern replacement for Google Container Registry (GCR) and integrates natively with Cloud Build and Cloud Run.

## Risks / Trade-offs

- **[Risk]** Cold-start latency on Cloud Run due to image size (FFmpeg/Python). → **Mitigation**: Use a Node.js `slim` base image and keep system packages to the bare minimum.
- **[Risk]** Local `.env` file inclusion in Docker image. → **Mitigation**: Use a robust `.dockerignore` file to ensure no sensitive local files are baked into the image.
- **[Risk]** Data Center (DC) connection issues from Cloud Run IPs. → **Mitigation**: The previous "Backend Resilience" changes already address some of this with improved retries.
