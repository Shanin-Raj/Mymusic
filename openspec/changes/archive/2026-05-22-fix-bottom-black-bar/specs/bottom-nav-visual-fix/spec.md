## ADDED Requirements

### Requirement: Bottom Navigation Background
The application MUST NOT display a harsh black linear gradient at the bottom navigation bar. Instead, the bottom navigation MUST use an elevated, semi-transparent background color (e.g., `rgba(20, 20, 20, 0.95)`) that aligns with the global `#000000` pitch-black theme.

#### Scenario: User scrolls to the bottom of a page
- **WHEN** the user is viewing any main screen (Home, Search, Library)
- **THEN** the bottom navigation bar blends naturally with the theme, utilizing a slight blur effect and avoiding any "stuck" solid black gradients
