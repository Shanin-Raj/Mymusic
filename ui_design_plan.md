# UI Design Plan: Spotify-Telegram Music Vault

This document outlines the UI/UX strategy for the **Music Vault** project, leveraging the **Sonic Immersion** design system (Project ID: `1212269696522831484`).

## 1. Design Philosophy: "Content as Protagonist"
The UI is designed to be an immersive, "lights-out" experience. By using a deep monochromatic base and glassmorphic accents, we ensure that high-fidelity album art and vibrant "Sonic Green" accents take center stage.

### Visual Identity
- **Theme**: Dark Mode (Premium Charcoal)
- **Aesthetic**: Minimalist with Glassmorphism
- **Primary Color**: `#1DB954` (Sonic Green)
- **Typography**: Montserrat (Bold Headlines) & Hanken Grotesk (Clean Body)

---

## 2. Design System: Sonic Immersion

### 🎨 Color Palette
| Token | Value | Usage |
| :--- | :--- | :--- |
| **Background** | `#121414` | Main application canvas |
| **Surface** | `#1e2020` | Cards and secondary containers |
| **Primary** | `#53e076` | Active states, high-action buttons |
| **Primary Container** | `#1db954` | Play buttons, key accents |
| **On Surface** | `#e3e2e2` | Primary text and headings |
| **Glass** | `rgba(28, 28, 28, 0.6)` | Blurry overlays (Player, Navigation) |

### 🔡 Typography
- **Headlines**: Montserrat (700) - Authoritative and geometric.
- **Body**: Hanken Grotesk (400-600) - High legibility for metadata and lists.

### 📐 Shape & Spacing
- **Corner Radius**: 8px (Standard), 16px (Large Cards/Modals), Fully Rounded (Artists/Play buttons).
- **Grid**: 4px baseline grid, 16px standard lateral margins.

---

## 3. Core Screen Architecture

### A. Home & Library (`bfc503bec734410aa47573533ec5d85a`)
- **Hero Section**: Welcome message with "Recently Played" quick-access grid.
- **Collections**: Horizontal scrolls for "Made for You" and "Top Playlists."
- **Track List**: High-density list of all songs in the Telegram-synced library.

### B. Now Playing (`1e209a6b6a564ac7aef595eff4362817`)
- **Glassmorphic Canvas**: Full-screen view with a blurred version of the current album art as the background.
- **Controls**: Large, pill-shaped play/pause buttons in Sonic Green.
- **Dynamic Progress**: 2px progress bar with micro-animations.

### C. Search & Discover (`9315c7eddea746a0a6a6beeb782bb0f1`)
- **Search Bar**: Surface-highlighted input with 50% opacity placeholder.
- **Trending Chips**: Quick filters for genres (Lo-fi, Pop, Jazz).
- **Live Results**: Instant feedback as the user types.

### D. Settings & Sync (`8c514faf24474f0e96def689a08f5357`)
- **Telegram Status**: Connection indicator for the MTProto backend.
- **Library Stats**: Total songs synced, storage used in Telegram channel.
- **API Configuration**: Secure fields for Client ID and Bot Token.

---

## 4. Key Components

### 🟢 The "Sonic" Play Button
- **Style**: Fully circular, Sonic Green background, black icon.
- **Animation**: Subtle scale-up (1.1x) on hover; ripple effect on click.

### 🪟 Glassmorphic Mini-Player
- **Placement**: Persistent at the bottom of the screen.
- **Effect**: `backdrop-filter: blur(20px)`, 60% opacity.
- **Feature**: Integrated 2px progress bar at the very top edge.

### 🗃️ Content Cards
- **Style**: 16px corner radius, tonal layering (no borders).
- **Hierarchy**: Large cards for promotional content; medium cards for albums.

---

## 5. Next Steps for Implementation
1.  **Tailwind Configuration**: Map the Sonic Immersion tokens to a `tailwind.config.js` (or vanilla CSS variables).
2.  **Layout Setup**: Implement the glassmorphic bottom navigation and persistent mini-player.
3.  **Data Binding**: Connect the React frontend to the Node.js backend (`main.js`) to fetch the `library.json` data.
4.  **Polish**: Add Framer Motion transitions between screens (Slide & Fade) to maintain the "flow" state.
