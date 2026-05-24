## 1. Foundation & Design Tokens

- [x] 1.1 Update CSS `:root` variables in `styles.css` with the Spotify dark theme color palette
- [x] 1.2 Update the base font stack to system-ui/Inter to mimic Circular
- [x] 1.3 Update common components (buttons, text styles, icons) to reflect the new visual aesthetic

## 2. App Shell & Navigation

- [x] 2.1 Refactor `#bottom-nav` in `index.html` to have 5 tabs (Home, Search, Your Library, Premium, Create)
- [x] 2.2 Update navigation CSS for layout and icons to match Spotify's style
- [x] 2.3 Modify `bindNavigation()` in `app.js` to correctly route the new 5 tabs and handle active states

## 3. Mini Player & Full Screen Player Updates

- [x] 3.1 Redesign `#mini-player` HTML structure to place album art left, title center, and controls right
- [x] 3.2 Update mini-player CSS for the docked placement above bottom nav and add the thin progress bar
- [x] 3.3 Redesign `#screen-player` (full screen player) HTML layout: context header, large art, seek bar, transport controls, and bottom action bar
- [x] 3.4 Update full screen player CSS for vertical scaling and responsive layout
- [x] 3.5 Verify player functionality (play/pause, next/prev, seek) remains intact in `app.js`

## 4. Screen Updates: Home

- [x] 4.1 Refactor `#screen-home` HTML to include user avatar, filter chips, and 2-column quick access grid
- [x] 4.2 Update home screen CSS for elevated cards and horizontal carousels
- [x] 4.3 Update `renderHome()` in `app.js` to populate the new home layout with recent songs and recommendations

## 5. Screen Updates: Search & Browse

- [x] 5.1 Refactor `#screen-search` HTML to use a rounded search bar and "Start browsing" grid
- [x] 5.2 Update search screen CSS for the colorful category cards and 2-column grid layout
- [x] 5.3 Update `bindSearch()` in `app.js` to toggle between the browse grid and search results list

## 6. Screen Updates: Your Library

- [x] 6.1 Refactor `#screen-library` HTML to add top filter chips and sorting controls
- [x] 6.2 Update library screen CSS to display items with square thumbnails and list layout
- [x] 6.3 Update `renderLibrary()` in `app.js` to match the new DOM structure

## 7. Final Polish

- [x] 7.1 Verify mobile responsiveness and safe-area insets across all screens
- [x] 7.2 Test playlist creation and track adding modals within the new design context
- [x] 7.3 Review animations and transition smoothness
- [x] 7.4 Remove any unused legacy CSS classes and unused code from `styles.css` and `index.html`
