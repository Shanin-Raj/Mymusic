## Why

Currently, `downloader.js` hardcodes the ffmpeg path to `/usr/bin/ffmpeg`. This fails on Windows systems, preventing `yt-dlp` from extracting audio and causing the download process to fail. We need a cross-platform solution to locate ffmpeg.

## What Changes

- Modify `downloader.js` to avoid hardcoding `/usr/bin/ffmpeg`.
- Introduce environment variable support for `FFMPEG_LOCATION`.
- If no environment variable is provided, omit the `--ffmpeg-location` flag so `yt-dlp` can rely on the system's `PATH`, or resolve `ffmpeg-static` if installed.

## Capabilities

### New Capabilities
- `ffmpeg-path-resolution`: Resolving the `ffmpeg` executable path across different operating systems for `yt-dlp`.

### Modified Capabilities
- 

## Impact

- Modifies `backend/downloader.js`
- Affects the backend environment configuration (supports `FFMPEG_LOCATION` in `.env`)
- Makes the audio extraction process cross-platform.
