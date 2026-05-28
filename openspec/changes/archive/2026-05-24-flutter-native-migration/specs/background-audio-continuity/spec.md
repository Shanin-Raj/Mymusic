## MODIFIED Requirements

### Requirement: Automatic Track Advancement on Lockscreen
The system SHALL transition to the next track in the queue automatically when the current track ends, regardless of whether the device screen is locked or the application is in the background. The system SHALL utilize the native Flutter background isolate (`audio_service`) to manage the queue and preload the subsequent track to ensure a seamless background transition.

#### Scenario: Successful transition in background
- **WHEN** the current track reaches its end (`ended` event) while the phone is locked
- **THEN** the native background audio service SHALL immediately load and play the next track in the current playlist
- **THEN** the Android system notification SHALL update to show the new track metadata

#### Scenario: Background pre-caching
- **WHEN** the active track has 45 seconds remaining
- **AND** the device is locked
- **THEN** the native audio service SHALL trigger a pre-cache request for the next song to ensure it is ready for an offline/background start

### Requirement: MediaSession Continuity
The system SHALL utilize native Android MediaSession integration (via Flutter `audio_service`) to maintain an active audio context. The system MUST register native listeners for `skipToNext` and `skipToPrevious` to ensure hardware/headset controls remain functional in the background, entirely bypassing web APIs.

#### Scenario: Background control interaction
- **WHEN** the user presses "Next" on a Bluetooth headset while the device is locked
- **THEN** the native audio service SHALL execute the queue advancement logic and begin playing the subsequent song