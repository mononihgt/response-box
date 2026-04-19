# `response-box-python` Agent Guide

Scope: this file applies to everything under `response-box-python/`.

## Purpose
- Provide Python-side serial utilities and PsychoPy experiment runtime for the response box.
- Keep hardware-facing behavior predictable, debuggable, and easy to validate manually.

## Directory Map
- `src/`: reusable modules (`serial_utils`, `reaction_box`, `pretest`, `test_utils`).
- `connection_test.py`: manual hardware diagnostics entrypoint.
- `experiment_psychopy.py`: end-to-end Stroop experiment script.
- `response_box_data/`: runtime CSV output directory.
- `docs/`: operator/user documentation.
- `../CH341SER Driver/`: workspace-level driver bundle used during device setup; keep Python docs aligned if this shared path changes.

## Engineering Rules
- Keep serial protocol details centralized in `src/reaction_box.py`.
- Keep port scanning/probing logic in `src/serial_utils.py`.
- Avoid adding experiment-specific logic into low-level serial modules.
- Keep public return keys stable (`key`, `t1`, `t2`, `press_duration`, `software_rt`, `system_delay`, `ide`).
- Prefer explicit failure handling over silent fallback in hardware paths.

## Validation Path
Run these checks after Python changes:

```bash
uv run python -m py_compile src/__init__.py src/serial_utils.py src/reaction_box.py src/test_utils.py src/pretest.py connection_test.py experiment_psychopy.py
```

If changes affect experiment flow, also run:

```bash
uv run connection_test.py
uv run experiment_psychopy.py
```

## Data and Artifacts
- Keep generated CSV files in `response_box_data/`.
- Do not commit personal participant data.
- Keep `.venv/`, `__pycache__/`, and OS artifacts out of versioned changes.
