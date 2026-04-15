param(
    [string]$Command = "run_experiment"
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$escapedRepoRoot = $repoRoot.Replace('\', '/').Replace("'", "''")

$matlabExe = $null
if ($env:MATLAB_EXE -and (Test-Path -LiteralPath $env:MATLAB_EXE)) {
    $matlabExe = $env:MATLAB_EXE
} else {
    $matlabCmd = Get-Command matlab -ErrorAction SilentlyContinue
    if ($matlabCmd) {
        $matlabExe = $matlabCmd.Source
    }
}

if (-not $matlabExe) {
    $commonCandidates = @(
        "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
        "C:\Program Files (x86)\MATLAB\R2025b\bin\matlab.exe"
    )
    foreach ($candidate in $commonCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            $matlabExe = $candidate
            break
        }
    }
}

if (-not $matlabExe) {
    Write-Error "MATLAB executable not found. Set MATLAB_EXE or add matlab.exe to PATH."
    exit 1
}

$matlabCommand = @(
    "cd('$escapedRepoRoot')"
    "rehash"
    "clear functions"
    $Command
    "exit"
) -join "; "

& $matlabExe -nosplash -nodesktop -r $matlabCommand
exit $LASTEXITCODE
