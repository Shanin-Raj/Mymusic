## Context

The bottom navigation currently uses a hardcoded black linear gradient (`rgba(0,0,0,0.9)` to `rgba(0,0,0,0.7)`). While initially we moved to a `#191414` Spotify background theme, on mobile screens this color can look brownish rather than dark and immersive. Furthermore, the gradient causes an uneven "black stuck" appearance at the bottom of the screen. We are moving the global app background to pure black (`#000000`).
In addition, the music player seek bar currently only registers taps/clicks. Dragging the slider does not smoothly update the playback position, leading to poor UX on mobile and desktop.

## Goals / Non-Goals

**Goals:**
- Update the global `--bg` variable to pure black (`#000000`) for a true pitch-black appearance on mobile.
- Update `.bottom-nav` background to be a solid/translucent elevated color (e.g., `#1e1e1e` or translucent equivalent) that matches the new pure black theme.
- Ensure the background gradient issue is resolved.
- Fix the seek bar slider so dragging the thumb smoothly seeks through the song.

**Non-Goals:**
- Changing the layout or icons of the bottom navigation.
- Rewriting the audio player from scratch.

## Decisions

- **Global Color**: We will update `--bg` to `#000000`.
- **Bottom Nav Color change**: We will update the `background` CSS property of `.bottom-nav` in `styles.css` to `rgba(20, 20, 20, 0.95)` (which is a slightly translucent elevated version of `#000000`) to give it slight separation from the pure black background.
- **Seek Bar Event Binding**: The `<input type="range">` seek bar currently only uses the `change` event or click event. We will bind an `input` event listener to it. The `input` event fires continuously as the user drags the slider, allowing us to update the audio `currentTime` (or a local visual state) smoothly.

## Risks / Trade-offs

- **Risk: Content clipping**: If `.screen` elements do not have enough `padding-bottom`, the last item might still be hidden behind the nav.
  - *Mitigation*: Verify that `.screen` has at least `120px` to `160px` of bottom padding to clear both the mini-player and bottom navigation.
- **Risk: Audio stuttering while dragging**: Continuously updating `audio.currentTime` on every `input` event might cause audio stuttering.
  - *Mitigation*: If stuttering occurs, we can pause the audio during the drag or handle the final seek strictly on the `change` event while only updating the UI during the `input` event.
