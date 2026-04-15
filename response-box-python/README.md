# Response Box Python

Python tooling and PsychoPy integration for the USB reaction box used in behavioral experiments.

## What This Project Includes
- `src/serial_utils.py`: serial discovery and device probing.
- `src/reaction_box.py`: low-level frame read/parse (`t1`, `t2`, `system_delay`).
- `src/pretest.py`: GUI pretest window for key checks before task start.
- `src/test_utils.py`: manual diagnostics helpers used by CLI menu.
- `connection_test.py`: command-line hardware diagnostics entrypoint.
- `experiment_psychopy.py`: full Stroop task example with data export.

## Quick Start
1. Install dependencies:
```bash
uv sync
```
2. Verify hardware connection:
```bash
uv run connection_test.py
```
3. Run the Stroop experiment:
```bash
uv run experiment_psychopy.py
```

## Data Contract
`get_reaction_time()` returns:
```python
{
    "key": 1,                 # physical key id (1-5)
    "t1": 387,                # key press latency in ms (primary RT)
    "t2": 542,                # key release latency in ms
    "press_duration": 155,    # t2 - t1 in ms
    "software_rt": 558.23,    # host-side elapsed time in ms
    "system_delay": 16.23,    # software_rt - t2 in ms
    "ide": 1                  # firmware checksum/marker
}
```
Use `t1` as the primary reaction-time variable in analysis.

## Project Layout
```text
response-box-python/
├── src/
├── docs/
├── CH341SER_DRIVER/
├── response_box_data/
├── connection_test.py
├── experiment_psychopy.py
├── build_mac.sh
├── build_windows.ps1
├── packaging_requirements.txt
└── pyproject.toml
```

## Engineering Notes
- Runtime-generated CSV files are written under `response_box_data/`.
- Hardware diagnostics are manual (no automated unit-test suite).
- The experiment task is designed for real device input; CI-safe checks should use syntax/import validation only.

## Validation Commands
- Syntax and import safety:
```bash
uv run python -m py_compile src/__init__.py src/serial_utils.py src/reaction_box.py src/test_utils.py src/pretest.py connection_test.py experiment_psychopy.py
```
- Optional local build smoke test:
```bash
uv run python -m compileall src connection_test.py experiment_psychopy.py
```

## Platform Requirements
- Python `>=3.10`
- `psychopy`, `pyserial`, `scipy`
- CH341/CH340 driver installed for the reaction box

## Troubleshooting
- Device not found: check USB cable, power, and CH341 driver install.
- Serial busy: close other apps that may hold the same COM/TTY port.
- Unexpected RT values: run calibration and detailed-parameter diagnostics from `connection_test.py`.
