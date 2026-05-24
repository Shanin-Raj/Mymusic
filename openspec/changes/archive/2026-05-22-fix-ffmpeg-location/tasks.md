## 1. Configure Downloader

- [x] 1.1 In `downloader.js`, retrieve `FFMPEG_LOCATION` from `process.env`.
- [x] 1.2 Modify the `args` array in `downloadSong` to conditionally include `--ffmpeg-location` and its value only if `FFMPEG_LOCATION` is defined and not empty.

## 2. Testing and Validation

- [x] 2.1 Test `yt-dlp` audio download with `FFMPEG_LOCATION` defined in `.env` to verify the specified path is respected.
- [x] 2.2 Test `yt-dlp` audio download without `FFMPEG_LOCATION` (or missing in `.env`) to verify it successfully falls back to system PATH.
