# response-box-eprime

E-Prime 3.0 implementation of the Response Box Stroop task, aligned to the behavior of the Python/PsychoPy version in this workspace.

## Scope

- This folder contains source assets for manually building `RB_Stroop.es3` in `E-Studio`.
- This folder does not contain a generated `.es3` binary project file.
- Hardware target is the serial response box (not keyboard simulation).

## Directory Map

- `ebasic/`: reusable `User Script` and `InLine` code snippets.
- `lists/`: `SessionList`, `TrialList`, and template CSV files.
- `runtime/`: PowerShell helper script for response-box port detection.
- `docs/`: setup guide, object map, data mapping, and validation checklist.

## Build and Run

1. Follow [docs/E_STUDIO_BUILD_STEPS.md](docs/E_STUDIO_BUILD_STEPS.md).
2. Create `RB_Stroop.es3` in `E-Studio` (target: E-Prime `3.0 (3.0.3.9)`).
3. Paste [ebasic/UserScript_RB_Stroop.ebs](ebasic/UserScript_RB_Stroop.ebs) into `User Script`.
4. Create objects listed in [docs/OBJECT_MAP.md](docs/OBJECT_MAP.md).
5. Paste each `InLine_*.ebs` file into its mapped object.
6. Populate `StartupInfo` from [lists/SessionList.csv](lists/SessionList.csv).
7. Detect the reaction box port before running the formal session:

```powershell
powershell -ExecutionPolicy Bypass -File .\runtime\detect_reaction_box.ps1
```

## Data and Behavior Contract

- Trial count: `12`.
- Core timings: mask `1000ms`, fixation `500ms`, response timeout `2000ms`, feedback `1000ms`, ITI `1000ms` for logged trials.
- White key (`5`) exits early by design.
- Exported fields and metric definitions are documented in [docs/DATA_MAPPING.md](docs/DATA_MAPPING.md).

## Validation

- Use [docs/VALIDATION_CHECKLIST.md](docs/VALIDATION_CHECKLIST.md) for hardware + behavior acceptance.
- Run at least one complete pilot session per machine after COM-port or driver changes.

## Current Limitations

- Verified against E-Prime `3.0.3.9`; behavior on other versions is not guaranteed.
- `software_rt` and `system_delay` are semantic equivalents of the Python pipeline, not guaranteed sample-by-sample identical.
