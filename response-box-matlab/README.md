# Response Box MATLAB

MATLAB Stroop experiment client for the USB response box.

It covers participant configuration, serial device pretest, formal experiment execution, and CSV export.

## Scope

This folder is the MATLAB implementation in the multi-language workspace:

- `response-box-ts`: browser/Web Serial implementation
- `response-box-python`: PsychoPy/Python implementation
- `response-box-matlab`: this implementation

## Project Structure

```text
response-box-matlab/
├── run_experiment.m              # Main entry point
├── run_matlab_safe.ps1           # Safer PowerShell launcher
├── +rbx/
│   ├── +config/                  # Default config and constants
│   ├── +serial/                  # Serial probing and frame parsing
│   ├── +ui/                      # Config and pretest UIs
│   ├── +experiment/              # Stimuli, task loops, analysis
│   ├── +io/                      # CSV export
│   └── +util/                    # Shared utilities
└── README.md
```

## Requirements

- MATLAB `R2019b+` minimum because this implementation uses `serialport`
- Validated on MATLAB `R2025b`
- Response box connected via USB serial
- CH340/CH341 driver if your hardware uses it
- Psychtoolbox optional; basic graphics fallback is built in

### MATLAB Version Compatibility

The MATLAB implementation depends on the modern `serialport` API for serial discovery, connection, and frame reads. MathWorks introduced `serialport` in MATLAB `R2019b`, so readers using MATLAB `R2019a` or earlier cannot run this project as-is.

If you are on an older MATLAB release, upgrade to `R2019b` or later before running the experiment. A legacy fallback would require code changes to replace `serialport` calls with the older `serial` interface, which is not currently implemented in this repository.

## Quick Start

Interactive run:

```matlab
cd('D:/Documents/response-box/response-box-matlab')
rehash
clear functions
run_experiment
```

Safer PowerShell launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_matlab_safe.ps1
```

## Experiment Flow

1. Fill participant and key-mapping configuration.
2. Auto-detect serial port and validate the device.
3. Run pretest window to confirm key events.
4. Start formal Stroop trials (`mask -> fixation -> stimulus -> feedback -> ITI`).
5. Press white key to abort early if needed.
6. Export CSV and print summary metrics.

## Output

Default output folder:

- Windows: `%USERPROFILE%\Documents\response_box_data\`
- macOS/Linux: `~/Documents/response_box_data/`

CSV fields include:

- Trial descriptors: `trial`, `word`, `color`, `congruent`, `correct_key`
- Response timing: `t1_press`, `t2_release`, `press_duration`, `software_rt`, `system_delay`
- Outcome fields: `response_key`, `response_name`, `correct`
- Participant metadata: `name`, `age`, `gender`, `date`, `time`, `task_type`

## Validation Commands

Quick MATLAB static analysis:

```powershell
& 'D:\Program Files (x86)\MATLAB\R2025b\bin\matlab.exe' -batch "checkcode('run_experiment.m','-id')"
```

Use the path for your installed MATLAB version. The project requires `R2019b+`; the `R2025b` path above is only an example from the validated environment.

Full folder static pass:

```powershell
& 'D:\Program Files (x86)\MATLAB\R2025b\bin\matlab.exe' -batch "entries=dir(fullfile(pwd,'**','*.m')); for i=1:numel(entries), f=fullfile(entries(i).folder,entries(i).name); msgs=checkcode(f,'-id'); if ~isempty(msgs), fprintf('ISSUES %s (%d)\n',f,numel(msgs)); end; end"
```
