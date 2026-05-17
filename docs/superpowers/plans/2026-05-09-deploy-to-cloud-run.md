# Deploy to Cloud Run Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the Music Vault application to Google Cloud Run in the `music-vault-shanin` project.

**Architecture:** Containerized Node.js backend serving a static frontend. Deployment via Cloud Build and Cloud Run.

**Tech Stack:** Docker, Google Cloud Run, Cloud Build, Node.js, Express.

---

### Task 1: Configure GCP Project and Enable Services

**Files:**
- N/A (Shell commands)

- [ ] **Step 1: Set the gcloud project**

Run: `gcloud config set project music-vault-shanin`

- [ ] **Step 2: Enable required APIs**

Run: `gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com`

---

### Task 2: Prepare Environment Variables

**Files:**
- Modify: `D:\music\backend\.env` (Read only)

- [ ] **Step 1: Extract environment variables from .env**

Read `D:\music\backend\.env` and prepare a list of `--set-env-vars` for the deploy command.
Variables to include:
- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_BOT_USERNAME`
- `TELEGRAM_API_ID`
- `TELEGRAM_API_HASH`
- `TELEGRAM_CHANNEL_ID`

---

### Task 3: Build and Push Container Image

**Files:**
- Modify: `D:\music\Dockerfile` (Ensure it's correct)

- [ ] **Step 1: Build and push the image using Cloud Build**

Run: `gcloud builds submit --tag gcr.io/music-vault-shanin/music-vault`

---

### Task 4: Deploy to Cloud Run

**Files:**
- N/A (Shell commands)

- [ ] **Step 1: Deploy the container**

Run: `gcloud run deploy music-vault --image gcr.io/music-vault-shanin/music-vault --platform managed --region us-central1 --allow-unauthenticated --set-env-vars "SPOTIFY_CLIENT_ID=...,SPOTIFY_CLIENT_SECRET=...,..."`
(Replace `...` with actual values from Task 2)

---

### Task 5: Final Verification

**Files:**
- N/A (Web check)

- [ ] **Step 1: Get the service URL**

Run: `gcloud run services describe music-vault --format 'value(status.url)'`

- [ ] **Step 2: Verify the API is responding**

Run: `curl -I <URL>/api/songs`
Expected: `HTTP/2 200` or `HTTP/2 500` (if library.json is empty/missing, but server should be up).
