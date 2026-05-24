## 1. Backend Resilience and Error Handling

- [x] 1.1 Update `backend/telegram.js` to increase `connectionRetries` and optimize client initialization settings for GramJS.
- [x] 1.2 Implement a robust reconnection wrapper for the Telegram client to handle mid-session drops.
- [x] 1.3 Refactor the song adding endpoint in `backend/main.js` to catch specific GramJS errors (timeout, DC mismatch) and return structured JSON error objects.

## 2. Frontend Design System and Styles

- [x] 2.1 Define "Sonic Immersion" color palette and typography as CSS custom properties in `backend/public/styles.css`.
- [x] 2.2 Apply dark mode base styles to the body and main containers, removing legacy light theme overrides.
- [x] 2.3 Implement Spotify-style component styles for cards, buttons, and text hierarchies.

## 3. Application Structure and Navigation

- [x] 3.1 Refactor `backend/public/index.html` to implement the 5-tab bottom navigation bar.
- [x] 3.2 Add the glassmorphic mini-player component to the `index.html` shell.
- [x] 3.3 Ensure all application screens (Home, Search, Library, etc.) are structured correctly to work with the new 5-tab navigation.

## 4. Frontend Logic and User Feedback

- [x] 4.1 Update `backend/public/app.js` to handle the new 5-tab navigation state management.
- [x] 4.2 Improve the \"Add Song\" UI logic to display real-time status updates (Fetching, Downloading, Uploading).
- [x] 4.3 Implement user-friendly error toast or modal to replace generic \"Code Error 1\" based on structured backend error responses.

## 5. Verification and Polish

- [x] 5.1 Verify successful song adding flow by testing with various Spotify URLs and monitoring backend logs for reconnection success.
- [x] 5.2 Perform a visual audit of all screens to ensure "Sonic Immersion" design tokens are applied correctly.
- [x] 5.3 Test the mini-player's persistence and glassmorphic appearance during navigation.
