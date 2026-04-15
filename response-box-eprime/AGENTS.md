# AGENTS.md (response-box-eprime)

Scope: applies to everything under `response-box-eprime/`.

## Purpose

Maintain the E-Prime implementation of the Stroop + reaction-box workflow so it stays behaviorally aligned with sibling implementations while remaining easy to rebuild in `E-Studio`.

## Directory Rules

- `ebasic/`: only shared script logic (`UserScript` and `InLine` snippets). Keep protocol constants centralized in `UserScript_RB_Stroop.ebs`.
- `lists/`: only CSV list/config templates used by `E-Studio` objects.
- `runtime/`: hardware integration helpers (PowerShell scripts and runtime JSON template/output).
- `docs/`: build guide, object map, field mapping, and acceptance checklist.

## Engineering Constraints

- Do not commit generated `.es3` binaries.
- Keep serial protocol handshake and frame parsing consistent between:
  - `ebasic/UserScript_RB_Stroop.ebs`
  - `runtime/detect_reaction_box.ps1`
- Preserve data contract fields documented in `docs/DATA_MAPPING.md` unless migration notes are added.
- Keep experiment timings explicit and centralized in code/constants.

## Validation Path

Run these focused checks after edits:

1. PowerShell syntax parse:
   `powershell -NoProfile -Command "$e=$null; $t=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('response-box-eprime/runtime/detect_reaction_box.ps1',[ref]$t,[ref]$e); if($e.Count){$e | ForEach-Object { $_.Message }; exit 1 }"`
2. Docs and object names consistency:
   `rg -n "RB_WaitFrame|TrialResponseInline|TrialList|SessionList|detect_reaction_box" response-box-eprime`
3. Runtime behavior validation:
   complete one manual device-connected run following `docs/VALIDATION_CHECKLIST.md`.

## Editing Guidance

- Keep changes minimal and folder-scoped.
- Prefer explicit, boring logic over compact clever code.
- If behavior changes, update `README.md` and the relevant file in `docs/` in the same change.
