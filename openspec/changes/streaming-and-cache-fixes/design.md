## Context

- Android's ExoPlayer uses chunked/range requests to stream audio, fetching metadata or initial chunks first, and then subsequent ranges.
- If multiple requests download and write to the same file path on disk concurrently, the file handles clash, leading to file corruption.
- Reading from a file while it is still being written to by another process can lead to partial streams or mismatches.

## Decisions

- **Single-Flight Download Helper (`downloadSongFromTelegram`):** Implement a single-flight helper using a promise cache Map (`activeDownloads`). If a request is made for a song that is already downloading, the server yields the *same* download promise rather than starting a new Telegram connection.
- **Atomic File Swapping:** Download the buffer into a `.tmp` file. Once the download completes, execute `fs.renameSync` to atomically rename it to `.m4a`. Renaming is an atomic operation on the operating system level, ensuring that reading processes either see no file (triggering download) or a completely finished, uncorrupted `.m4a` file.
- **Real-Time `onSnapshot` Synchronizers:** By running `onSnapshot` listeners on backend startup, we bypass any cache TTL concerns. The local server memory arrays (`songsCache`, `playlistsCache`) are updated in real-time, resulting in immediate database synchronization and 0ms GET API latencies.
