## ADDED Requirements

### Requirement: Persistent Recent Searches
The search screen SHALL maintain a list of persistent recent searches using `SharedPreferences`. Tapping a song from the search results MUST add it to the top of the recent searches list. The list SHALL display a maximum of 10 unique recently searched songs.

#### Scenario: Tap search result adds to history
- **WHEN** the user searches for a track and taps it to play
- **THEN** the track ID is saved locally and placed at the top of the "Recent searches" list.

### Requirement: Recent Search Deletion
Each recent search list item SHALL feature a close ("x") icon on the right. Tapping the close icon MUST remove that item from the recent searches list and delete it from local persistence instantly.

#### Scenario: Deleting a recent search
- **WHEN** the user taps the close ("x") icon next to a song in the "Recent searches" list
- **THEN** the song is removed from the screen immediately and deleted from SharedPreferences history.
