## Context

Node.js scripts running outside of the Express server (like `main.js` and `manual_add.js`) need to explicitly load the `.env` file to access API keys. `manual_add.js` has `require('dotenv').config({ path: require('path').join(__dirname, '.env') });` at line 1, but `main.js` is missing it.

## Goals / Non-Goals

**Goals:**
- Enable `main.js` to read environment variables successfully.

## Decisions

- **Decision 1: Explicit `.env` pathing**
  - *Rationale*: We will use the exact same `dotenv` initialization logic from `manual_add.js` in `main.js` to ensure consistency.

## Risks / Trade-offs

- **Risk**: None. This is a standard missing-dependency bug fix.
