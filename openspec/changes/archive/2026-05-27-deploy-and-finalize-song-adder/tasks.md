## 1. Telegram Ephemeral Socket Connection Overhaul

- [x] 1.1 Modify `backend/telegram.js` to instantiate fresh TelegramClient connections per operation.
- [x] 1.2 Disconnect and destroy Telegram client connections cleanly in finally block.
- [x] 1.3 Update `backend/server.js` with robust dual image-path checks.

## 2. Infrastructure Build Optimization

- [x] 2.1 Update `.gcloudignore` to exclude massive Flutter build directories and IDE folders.
- [x] 2.2 Reduce tarball upload size from 2.4 GB to 74 MB.

## 3. Google Cloud Production Deployments

- [x] 3.1 Trigger Cloud Build to package the optimized container code in the cloud.
- [x] 3.2 Deploy the built image to the us-central1 regional `sonic-vault` service.
- [x] 3.3 Deploy the built image directly to the active production `music-vault` service in `asia-south1` to immediately enable hotfixed backend services for mobile clients.
