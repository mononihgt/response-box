# `response-box-ts` Agent Guide

This file applies to everything under `response-box-ts/`.

## Purpose

Web Serial Stroop experiment client for response-box hardware.
Keep changes focused on reliability, data integrity, and experiment correctness.

## Directory Map

- `src/main.ts`: UI flow and experiment orchestration.
- `src/serial/`: serial port I/O and protocol handling.
- `src/experiment/`: trial generation, statistics, CSV export.
- `src/styles/`: app styling.
- `src/types/`: Web Serial type declarations.

## Engineering Rules

- Keep modules single-purpose; avoid adding unrelated logic to `src/main.ts`.
- Preserve strict TypeScript compatibility (`tsconfig.json`).
- Do not change serial protocol bytes (`0xFB`, `0xFC`) unless explicitly requested.
- Treat participant/trial data as append-only during runtime; avoid mutating recorded trials.
- Prefer deterministic validation and explicit error paths over silent fallbacks.

## Validation

Minimum after code changes:

```bash
npm run build
```

If UI/flow changed, also manually verify in Chromium browser:

- Connect to device and run connection test.
- Run at least one full experiment.
- Test white-key early exit and CSV export.

## Data/Procedure Constraints

- Red and green key mappings must differ.
- Trial count and timing parameters must stay bounded by UI constraints.
- Keep the trial sequence explicit and traceable (`mask -> fixation -> stimulus -> response -> feedback -> ITI`).

## Out Of Scope

- Do not edit sibling projects from this scope (`../response-box-python`, `../response-box-matlab`, `../response-box-eprime`).
