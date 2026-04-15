# Response Box Web (TypeScript + Web Serial)

Browser-based reaction-box experiment app for Stroop tasks.
It connects to CH340/CH341 serial hardware through Web Serial, runs timed trials in fullscreen, and exports trial-level CSV data.

## Scope

- Project folder: `response-box-ts/`
- Tech stack: TypeScript, Vite, Web Serial API
- Runtime target: Chromium-based desktop browsers

## Features

- Serial connection to reaction box (`115200` baud)
- Stroop `color` mode (respond by ink color)
- Stroop `word` mode (respond by word meaning)
- Configurable key mapping (red/green), trial count, timeout, feedback duration
- Trial-by-trial reaction data capture (`t1`, `t2`, press duration, software RT, system delay)
- CSV export with participant metadata and per-trial fields
- White-key early termination path with partial-data preservation

## Requirements

- Browser: Chrome or Edge with Web Serial support
- Context: `https://` or `http://localhost`
- Node.js: 18+ (recommended for build/dev)
- Hardware driver: CH340/CH341 installed on host machine

## Development

```bash
cd response-box-ts
npm install
npm run dev
```

Build and preview:

```bash
npm run build
npm run preview
```

## Structure

```text
response-box-ts/
├── index.html
├── src/
│   ├── main.ts
│   ├── experiment/
│   │   ├── ExperimentManager.ts
│   │   └── StroopTask.ts
│   ├── serial/
│   │   ├── ReactionBox.ts
│   │   └── SerialUtils.ts
│   ├── styles/
│   │   └── main.css
│   └── types/
│       └── web-serial.d.ts
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Experiment Flow

1. Connect serial device.
2. (Optional) Run connection test and inspect live key responses.
3. Fill participant/task config and key mapping.
4. Read instructions, then start task.
5. Per trial: mask -> fixation -> stimulus -> hardware response -> feedback -> ITI.
6. Finish normally or stop with white key.
7. Save CSV (directory picker first, browser download fallback).

## Output Data Fields

CSV headers:

`participant_id, participant_age, participant_gender, task_type, trial_number, stimulus_type, stimulus, correct_key, response_key, t1, t2, press_duration, software_rt, system_delay, correct, timestamp`

## Validation Checklist

- Run `npm run build` after changes.
- Manual sanity run in Chrome/Edge for:
- Connect/disconnect path
- Connection test page
- Full experiment loop
- White-key abort behavior
- CSV export (directory picker and fallback download)

## Current Limits

- Web Serial is unavailable on Firefox/Safari.
- No automated unit/integration tests in this folder.
- Stimulus set currently uses two colors/words (red/green only).
