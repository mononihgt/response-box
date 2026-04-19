# MATLAB Folder Guide

Scope: this file applies to everything under `response-box-matlab/`.

## Purpose

This folder contains the MATLAB Stroop implementation for the response box, including serial communication, UI flow, experiment loop, and CSV export.

## Directory Rules

- Keep MATLAB package layout under `+rbx/`.
- Put reusable logic in `+rbx/*` modules, not in `run_experiment.m`.
- Keep `run_experiment.m` as orchestration only.
- Keep serial protocol handling in `+rbx/+serial/`.
- Keep experiment logic in `+rbx/+experiment/`.

## Coding Conventions

- MATLAB code uses 4-space indentation.
- Function names use `snake_case` to match existing modules.
- Prefer explicit structs and documented fields for trial/result rows.
- Avoid cross-module side effects; pass state through arguments/returns.
- Preserve MATLAB `R2019b+` compatibility unless the user explicitly asks to raise the minimum version; serial I/O uses the `serialport` API introduced in `R2019b`.

## Validation

- For edited files, run `checkcode(..., '-id')`.
- For workflow changes, run a full-folder static pass with `checkcode`.
- Hardware/interactive checks are manual:
  - serial pretest in `run_experiment`
  - one full trial run with real device

## Safety and Quality

- Do not commit machine-specific artifacts (`.DS_Store`, autosave files).
- Preserve CSV schema compatibility unless a coordinated migration is requested.
- Keep experiment timing parameters centralized in `+rbx/+config/default_config.m`.
