# Render Migration Plan - Sonic Vault

This document outlines the step-by-step procedure to migrate the "Sonic Vault" backend from Google Cloud Run to Render (Free Tier, no credit card required) and configure the system for zero-maintenance hosting.

---

## 1. Prerequisites & Readiness

- **Containerization**: The codebase uses a standard `Dockerfile` in the root directory. Render supports native Docker deployments out of the box.
- **Configurable Credentials**: `backend/firebase.js` is fully refactored to parse service account keys from the `FIREBASE_KEY_JSON` environment variable, eliminating the need to commit secret files.

---

## 2. Step-by-Step Migration Steps

### Step 2.1: Code Repository Preparation
1. Ensure the latest version of the repository is pushed to your remote Git platform (GitHub or GitLab).
2. Render deploys directly from connected Git repositories, facilitating automatic rebuilds on every `git push`.

### Step 2.2: Provision a Web Service on Render
1. Go to the [Render Dashboard](https://dashboard.render.com/) and sign up.
2. Click **New +** in the top navigation bar and select **Web Service**.
3. Connect your GitHub/GitLab account and select the `music` repository.
4. Configure the service settings:
   - **Name**: `sonic-vault-backend` (or your preferred identifier)
   - **Region**: Select the closest region (e.g., `Singapore` or `Oregon`)
   - **Branch**: `main`
   - **Runtime**: `Docker`
   - **Instance Type**: `Free`

### Step 2.3: Populate Environment Variables
In the Render Web Service settings, navigate to the **Environment** tab, click **Add Environment Variable**, and populate the following keys:

| Environment Variable | Value / Source | Description |
| :--- | :--- | :--- |
| `PORT` | `8080` | The port the backend server listens on. |
| `TELEGRAM_API_ID` | Your Telegram API ID | Obtained from your `.env` file |
| `TELEGRAM_API_HASH` | Your Telegram API Hash | Obtained from your `.env` file |
| `TELEGRAM_BOT_TOKEN` | Your Telegram Bot Token | Obtained from your `.env` file |
| `TELEGRAM_CHANNEL_ID` | Your Telegram Channel ID | Obtained from your `.env` file |
| `TELEGRAM_SESSION` | Your Telegram Session string | Obtained from your `.env` file |
| `FIREBASE_KEY_JSON` | Content of `backend/firebase-key.json` | **CRITICAL**: Copy the *entire* raw JSON content and paste it as a single string. |

Click **Save Changes**. Render will automatically queue a new deployment using your configuration.

---

## 3. Post-Deployment Handshakes

Once Render successfully deploys the service and assigns a public domain (e.g., `https://your-service.onrender.com`):

### 3.1 Server-Side Integration (Asset Links)
1. Open [manifest.json](file:///d:/music/backend/public/manifest.json) in your project.
2. Under `related_applications`, update the `url` value to point to your new Render asset links handler:
   `https://your-service.onrender.com/.well-known/assetlinks.json`

### 3.2 Android App Redirect
1. To redirect the native Android app container to the new host, open the `android/twa-manifest.json` file.
2. Locate the `"host"` configuration property and update it to your new Render subdomain (e.g., `your-service.onrender.com`).
3. Re-run building utilities:
   ```powershell
   bubblewrap update
   bubblewrap build
   ```

---

## 4. Preventing Render Free Tier Sleeping

On Render's Free tier, the container spins down automatically after **15 minutes of inactivity**, causing the next visitor to experience a 30-50 second cold start. To prevent this sleeping state, configure an external ping monitor:

### Option A: UptimeRobot (Recommended)
1. Register a free account at [UptimeRobot](https://uptimerobot.com/).
2. Click **Add New Monitor**.
3. Configure the monitor properties:
   - **Monitor Type**: `HTTPS`
   - **Friendly Name**: `Sonic Vault KeepAlive`
   - **URL (or IP)**: `https://your-service.onrender.com/` (use your actual Render URL)
   - **Monitoring Interval**: `10 minutes` (keeps the container active before the 15-minute shutdown threshold triggers)
4. Save the monitor.

### Option B: Cron-Job.org
1. Create a free account at [cron-job.org](https://cron-job.org/).
2. Create a new cron job.
3. Configure:
   - **Title**: `Sonic Vault KeepAlive`
   - **Address**: `https://your-service.onrender.com/`
   - **Schedule**: `Every 12 minutes`
4. Save the cron job.
