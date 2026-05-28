## ADDED Requirements

### Requirement: Manual Refresh Action
The system SHALL provide a manual refresh button in the primary Library view's app bar. Tapping this button MUST invalidate the client's song cache, invoke backend services to retrieve newly added songs or playlist details immediately, and trigger a visual confirmation via SnackBar upon completion.

#### Scenario: User clicks refresh in Library
- **WHEN** the user taps the refresh action button in the Library app bar
- **THEN** the system invalidates song cache and initiates fresh network requests
- **THEN** it reloads the view with updated listings and shows a snackbar confirmation
