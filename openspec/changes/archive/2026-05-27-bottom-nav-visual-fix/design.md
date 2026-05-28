## Context

On modern Android devices with hardware or soft-key system navigation bars, bottom sheets triggered from the library actions clipped under the bottom screen boundaries.

## Goals / Non-Goals

**Goals:**
- Inject safe bottom area paddings to all modal bottom sheets triggered by the library navigation.

**Non-Goals:**
- Customizing global bottom sheets unrelated to library actions.

## Decisions

- **Decision 1: Use MediaQuery for dynamic paddings**
  - *Choice*: Change `padding: const EdgeInsets.symmetric(vertical: 20)` to `padding: EdgeInsets.only(top: 20, bottom: MediaQuery.of(context).padding.bottom + 20)`.
  - *Rationale*: Safe-area values dynamically adjust across notch styles and gestures.

## Risks / Trade-offs

- None.
