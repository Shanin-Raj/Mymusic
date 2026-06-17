## Context

- The Firebase Admin Node SDK throws an error if an object with `undefined` properties is passed to a document reference's `.set()` or `.update()` functions.
- The memory-cache on the backend is extremely fast, but caching collections forever results in stale responses when updates happen outside the API interface (such as via direct Firestore writes from the backend command-line tool).
- Keeping multiple Render free services awake 24/7 requires distinct, unshared workspaces to avoid hitting the 750-hour monthly limit.

## Decisions

- **ignoreUndefinedProperties Setting:** Instead of trying to strip undefined values manually in every CLI, background job, or utility file, we set `ignoreUndefinedProperties: true` globally on the Firestore instance in `firebase.js`.
- **Minified Environment Variable:** We minified the raw Firebase private key JSON into a single line to prevent Render from misinterpreting raw newlines as separate variable scopes or syntax separators.
- **30-Second TTL Cache Invalidation:** Instead of maintaining complex state synchronization between the CLI process and the API server process, we implemented a 30-second TTL on `songsCache` and `playlistsCache` in `server.js`. The server queries the database again if the cache is older than 30 seconds, automatically fetching any songs added via CLI.
- **Dedicated Hosting Account:** Migrating the app's backend to a separate Render account ensures 24/7 availability on the Free tier via UptimeRobot without exhausting hours meant for other projects.
