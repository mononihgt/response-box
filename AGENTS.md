# Repository Guidelines

## Workspace Purpose
This workspace collects response-box experiment implementations for multiple runtimes. Treat each project folder as an independently runnable package with its own dependencies, validation path, and runtime constraints.

## Project Map
- `response-box-ts/`: TypeScript + Vite browser app using the Web Serial API.
- `response-box-python/`: Python utilities, serial diagnostics, PsychoPy Stroop experiment, drivers, and user docs.
- `response-box-matlab/`: MATLAB Stroop experiment with namespaced helpers under `+rbx/`.
- `response-box-eprime/`: E-Prime implementation assets, E-Basic inline scripts, list files, runtime config, and build docs.

Each child folder may also be an independent Git repository. Do not assume the workspace root is the canonical Git root.

## Structure Rules
- Keep runtime-specific code inside its project folder; do not share code by copying between runtimes unless the user asks.
- Put reusable implementation code in source/helper modules, not in top-level launcher scripts.
- Keep generated files, caches, logs, and local environments out of versioned source when possible.
- Preserve hardware support assets such as `CH341SER_DRIVER/`, E-Prime `runtime/` templates, and experiment list files unless the task explicitly changes them.
- Prefer scoped `AGENTS.md` files for project-specific rules.

## Development Commands
TypeScript:
- `cd response-box-ts && npm install`: install dependencies.
- `npm run dev`: run the Vite dev server.
- `npm run build`: type-check and build to `dist/`.
- `npm run preview`: preview the production build.

Python:
- `cd response-box-python && uv sync`: install/update the Python environment.
- `uv run connection_test.py`: run serial connection diagnostics.
- `uv run experiment_psychopy.py`: run the interactive PsychoPy experiment.
- `python connection_test.py`: fallback when `uv` is unavailable.

MATLAB:
- Open `response-box-matlab/` as the working folder.
- Run `run_experiment.m` from MATLAB.
- Use `run_matlab_safe.ps1` only as a local launch helper.

E-Prime:
- Use `response-box-eprime/docs/E_STUDIO_BUILD_STEPS.md` to assemble or update the `.es3` experiment.
- Keep `.ebs` inline snippets aligned with object names documented in `docs/OBJECT_MAP.md`.
- Validate with `docs/VALIDATION_CHECKLIST.md` before collecting data.

## Coding Style
- TypeScript: 2-space indentation, semicolons, `camelCase` variables/functions, `PascalCase` classes.
- Python: 4-space indentation, `snake_case` modules/functions, short docstrings for public APIs.
- MATLAB: one public function per file where practical, package helpers under `+rbx/+domain/`, descriptive names.
- E-Basic: keep inline files named after their E-Studio objects and avoid hidden global state.

## Experiment Engineering
- Keep trial generation, device I/O, timing, response parsing, and data export as separate responsibilities.
- Validate participant/session metadata before experiment start.
- Record enough data to audit timing: stimulus identity, condition, expected response, actual response, correctness, reaction time, timeout/missing-response status, and timestamps when available.
- Keep practice/pretest flows separate from formal data collection.
- Do not silently continue after serial-device failures unless the mode is explicitly documented as keyboard/demo fallback.

## Validation Expectations
- Start with the narrowest deterministic check for changed code.
- For TS changes, run `npm run build` and manually verify connect/test/export flows when hardware/browser access is available.
- For Python changes, run import/compile checks and use `uv run connection_test.py` plus a full PsychoPy pass when hardware/display access is available.
- For MATLAB and E-Prime changes, run available static checks and document any runtime checks blocked by proprietary tooling or hardware.
- Never claim hardware timing correctness from static checks alone.

## Documentation Rules
- Keep each project README focused on install, run, structure, data outputs, validation, and known limits.
- Keep root docs as a map; put runtime-specific detail in the child project.
- Use emojis sparingly and only when they improve scanability.
- Update docs whenever behavior, commands, output schema, or experiment procedure changes.

## Safety
- Treat serial ports, hardware drivers, experiment data, workflow files, and agent configuration as sensitive control surfaces.
- Do not hardcode participant-identifying information or credentials.
- Do not delete collected data, driver assets, or runtime templates unless the user explicitly requests it.
