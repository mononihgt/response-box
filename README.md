# Response Box Workspace

This workspace contains four response-box experiment implementations that target different runtimes. Use the root as a navigation point; run and validate each project from its own folder.

## Projects
- `response-box-ts/`: browser-based Web Serial implementation built with TypeScript and Vite.
- `response-box-python/`: Python serial utilities, connection diagnostics, PsychoPy Stroop experiment, drivers, and user manuals.
- `response-box-matlab/`: MATLAB Stroop experiment using package helpers under `+rbx/`.
- `response-box-eprime/`: E-Prime build assets, E-Basic inline scripts, list files, runtime config, and validation docs.

## Quick Start
TypeScript:
```powershell
cd response-box-ts
npm install
npm run dev
```

Python:
```powershell
cd response-box-python
uv sync
uv run connection_test.py
uv run experiment_psychopy.py
```

MATLAB:
```powershell
cd response-box-matlab
.\run_matlab_safe.ps1
```

E-Prime:
```text
Open E-Studio and follow response-box-eprime/docs/E_STUDIO_BUILD_STEPS.md.
```

## Engineering Notes
- Each project has its own runtime assumptions and may be an independent Git repository.
- Keep device I/O, experiment logic, UI flow, and data export separated.
- Generated artifacts such as `node_modules/`, `.venv/`, caches, build output, and local logs should remain untracked.
- Hardware validation requires a CH341/USB serial response box and cannot be proven by builds or static checks alone.

## Validation Matrix
- TypeScript: `npm run build`, then manual browser checks for connect, test, run, and export flows.
- Python: import/compile checks, `uv run connection_test.py`, then a full `uv run experiment_psychopy.py` pass when display and hardware are available.
- MATLAB: static parse checks where available, then a MATLAB run of `run_experiment.m`.
- E-Prime: review docs/list/script consistency, assemble in E-Studio, then follow `docs/VALIDATION_CHECKLIST.md`.

## Agent Guidance
Read `AGENTS.md` at the workspace root first, then any project-scoped `AGENTS.md` files. Prefer focused changes inside one project at a time and record validation limits clearly.
