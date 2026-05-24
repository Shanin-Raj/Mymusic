## Context

Currently, the audio download process uses `yt-dlp` via `downloader.js`. It passes a hardcoded `--ffmpeg-location /usr/bin/ffmpeg` argument. On Windows systems, this path does not exist, causing the process to fail with a `ffprobe and ffmpeg not found` error. We need to make this cross-platform.

## Goals / Non-Goals

**Goals:**
- Allow the path to `ffmpeg` to be configured dynamically.
- Support a fallback mechanism that relies on the system's `PATH`.
- Fix audio conversion errors on Windows.

**Non-Goals:**
- We will not automatically download or bundle `ffmpeg` binaries to keep dependencies light. Users must install `ffmpeg` themselves or rely on the environment variable.

## Decisions

- **Use an Environment Variable for configuration (`FFMPEG_LOCATION`)**: Instead of hardcoding `/usr/bin/ffmpeg`, we will check `process.env.FFMPEG_LOCATION`. If it is set, we will use it.
- **Fallback to omitting the argument**: If `FFMPEG_LOCATION` is not set, we will omit the `--ffmpeg-location` flag entirely. This allows `yt-dlp` to search the system's `PATH` for `ffmpeg`, which is standard behavior on both Windows and Linux if properly configured.
- **Rationale**: This provides maximum flexibility. Users can rely on system installations without configuration, or explicitly specify paths in `.env` if they are using non-standard locations.

## Risks / Trade-offs

- [Risk] If a user does not have `ffmpeg` installed globally (in `PATH`) and doesn't specify `FFMPEG_LOCATION`, `yt-dlp` will still fail. → Mitigation: Surface the `yt-dlp` error clearly so the user knows to install `ffmpeg` or configure the `.env` variable.
