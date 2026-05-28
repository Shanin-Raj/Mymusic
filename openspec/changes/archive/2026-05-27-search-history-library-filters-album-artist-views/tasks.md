## 1. Storage and Search History Management

- [x] 1.1 Add recent search persistence methods (`getRecentSearches()`, `addRecentSearch()`, `removeRecentSearch()`) in `StorageService` using `SharedPreferences`
- [x] 1.2 Refactor `SearchView` in `main_screen.dart` to load history, populate dynamic search history lists, delete items on close icon taps, and register song selections in memory

## 2. Library Option List and Filtering

- [x] 2.1 Delete the "Podcasts & Shows" chip from `LibraryOptionsList` in `library_options_list.dart`
- [x] 2.2 Implement active state style parameters in `LibraryOptionsList` using filled green background and dark text for selected chips
- [x] 2.3 Update `LibraryView` state inside `main_screen.dart` to support interactive filtering (`Playlists`, `Artists`, `Albums`, default) and render correct slivers dynamically

## 3. Figma-Style Dynamic Album Screen

- [x] 3.1 Create `screens/album_detail_screen.dart` implementing the red-gradient Figma mockup background and header spacing
- [x] 3.2 Implement dynamic data mapping: filter songs by the selected `album` field from Firebase, loading first song's art as the cover, and display dynamic track tiles
- [x] 3.3 Wire play/shuffle actions inside `AlbumDetailScreen` to play the album's tracks

## 4. Figma-Style Dynamic Artist Screen

- [x] 4.1 Create `screens/artist_detail_screen.dart` implementing the blue-gradient Figma mockup background and circular profile layout
- [x] 4.2 Write a robust dynamic parser that extracts, splits, and cleans composite artist strings from Firebase metadata, avoiding special unicode characters
- [x] 4.3 Implement dynamic data mapping: filter songs where `artist` metadata contains the selected artist name, displaying dynamic track tiles
- [x] 4.4 Wire play/shuffle actions inside `ArtistDetailScreen` and map navigation triggers from Library's unique Artists and Albums lists
