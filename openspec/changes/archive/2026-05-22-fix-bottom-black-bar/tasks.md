## 1. CSS Updates

- [x] 1.1 In `styles.css`, locate `--bg` in `:root` and change it from `#191414` to `#000000`.
- [x] 1.2 In `styles.css`, locate `.bottom-nav` and replace `background: linear-gradient(...)` with `background: rgba(20, 20, 20, 0.95);` (a slightly elevated color above pure black).
- [x] 1.3 In `styles.css`, locate `.screen` and verify that `padding-bottom` is sufficient (e.g., `160px` to `180px`) so no content is blocked by the transparent bottom nav and mini player.
- [x] 1.4 Remove any remaining hard-coded linear gradients from the `.screen` or `#app-shell` CSS blocks that cause "stuck black" bands at the bottom of the content.

## 2. JS Interaction Updates

- [x] 2.1 In `app.js` (or the relevant player script), locate the event bindings for the seek bar (`#seek-bar` or `.seek-bar` input range element).
- [x] 2.2 Add an `input` event listener to the seek bar to handle continuous updates during a drag.
- [x] 2.3 Ensure that dragging the slider smoothly seeks the audio track without stuttering (e.g. by pausing updates from `timeupdate` while dragging).
