# main-js-env Specification

## Purpose
Ensures environment configuration is correctly loaded for the backend CLI tool.

## Requirements

### Requirement: Environment Configuration
The script MUST load environment variables from the `.env` file located in the same directory before executing any other logic.

#### Scenario: Script Initialization
- **WHEN** `main.js` is executed via Node.js
- **THEN** it MUST use `dotenv` to load the `.env` file so that `process.env.TELEGRAM_API_ID` and other credentials are available to imported modules.
