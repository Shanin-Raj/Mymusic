## Why

After implementing the Spotify UI color fixes, there is still a noticeable black box/gradient stuck at the bottom of the screen (behind the bottom navigation bar). Furthermore, the currently applied `#191414` background color appears brownish on mobile screens rather than the deep, immersive black expected of a premium app. Lastly, the music player seek bar (slider) is currently broken; it only works when tapped, but dragging the slider handle does not work smoothly.

## What Changes

- **Global Background Color**: Update the global `--bg` color to pure black (`#000000`) instead of the brownish `#191414` to ensure it looks dark and immersive on mobile screens.
- **Bottom Navigation Background**: Remove the hardcoded black-to-black linear gradient on `.bottom-nav`.
- **Theme Matching**: Update the bottom navigation bar's background to use a semi-transparent elevated color (e.g., `rgba(30, 30, 30, 0.95)`) with a blur filter to seamlessly blend with the new pitch-black UI.
- **Screen Padding Fixes**: Ensure that the `.screen` elements have appropriate `padding-bottom` so content isn't obscured by the bottom nav and doesn't leave an empty black void.
- **Seek Bar Interaction Fix**: Update the event listeners on the seek bar in the JavaScript logic. We will bind to the `input` event (for smooth dragging updates) in addition to the `change` event.

## Capabilities

### New Capabilities
- `bottom-nav-visual-fix`: Standardize the bottom navigation background color to match the Spotify design system and remove the stuck black gradient.
- `pure-black-theme`: Change the global app background from `#191414` to pure black (`#000000`).
- `seek-bar-fix`: Fix the music player slider so that it can be smoothly dragged, not just tapped.

### Modified Capabilities
_(none)_

## Impact

- **Frontend CSS**: `styles.css` is affected for color changes.
- **Frontend JS**: `app.js` (or similar file handling the audio player) is affected to update the event listener on the range slider.
