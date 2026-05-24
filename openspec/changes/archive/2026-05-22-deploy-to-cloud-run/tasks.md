## 1. Containerization Setup

- [x] 1.1 Create an optimized `Dockerfile` in the project root, including FFmpeg and Python installation.
- [x] 1.2 Create a `.dockerignore` file to exclude `node_modules`, `.env`, and other local artifacts from the build.

## 2. Server Adaptation

- [x] 2.1 Update `backend/server.js` to use `process.env.PORT || 8080` for the listening port.

## 3. Deployment Configuration

- [x] 3.1 Create a `deploy.sh` script (or document the steps) for building the image with Cloud Build and deploying to Cloud Run.
- [x] 3.2 Verify that all required environment variables are listed for manual entry in the Cloud Run configuration.

## 4. Verification

- [x] 4.1 Perform a trial build of the Docker image locally to ensure all system dependencies (FFmpeg) are correctly installed.
- [x] 4.2 Validate the final deployment by checking the Cloud Run service URL.
