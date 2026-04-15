param(
    [switch]$AsJson,
    [string]$WriteJsonPath
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Core | Out-Null

function Get-CandidatePorts {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
    $candidates = @()

    foreach ($port in $ports) {
        $pnp = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -like "*($port)" -or $_.Caption -like "*($port)" -or $_.DeviceID -like "*$port*"
            } |
            Select-Object -First 1

        $label = ''
        if ($pnp) {
            $label = ($pnp.Name, $pnp.Caption, $pnp.DeviceID | Where-Object { $_ } | Select-Object -First 1)
        }

        $upper = [string]::Join(' ', $label).ToUpperInvariant()
        $priority = 1
        if ($upper -match 'CH340|CH341|WCHUSB|USB-SERIAL|USB SERIAL') {
            $priority = 0
        }

        $candidates += [pscustomobject]@{
            Port = $port
            Priority = $priority
            Label = [string]::Join(' | ', $label)
        }
    }

    $candidates | Sort-Object Priority, Port
}

function Test-ReactionBoxPort {
    param([string]$PortName)

    $sp = New-Object System.IO.Ports.SerialPort $PortName,115200,'None',8,'One'
    $sp.ReadTimeout = 1000
    $sp.WriteTimeout = 1000

    try {
        $sp.Open()
        $sp.DiscardInBuffer()
        $sp.DiscardOutBuffer()
        $sp.Write([byte[]](0x5A,0x00), 0, 2)
        Start-Sleep -Milliseconds 50

        $buffer = New-Object byte[] 32
        $offset = 0
        $deadline = (Get-Date).AddMilliseconds(1000)

        while ((Get-Date) -lt $deadline) {
            $count = $sp.BytesToRead
            if ($count -gt 0) {
                if ($offset + $count -gt $buffer.Length) {
                    $count = $buffer.Length - $offset
                }
                $read = $sp.Read($buffer, $offset, $count)
                $offset += $read
                if ($offset -gt 0) { break }
            }
            Start-Sleep -Milliseconds 10
        }

        if ($offset -lt 2) {
            return $null
        }

        if ($buffer[0] -ne 0x5A) {
            return $null
        }

        $deviceId = ''
        if ($offset -ge 3) {
            $deviceId = '{0:X2}{1:X2}' -f $buffer[1], $buffer[2]
        } elseif ($offset -ge 2) {
            $deviceId = '{0:X2}' -f $buffer[1]
        }

        return [pscustomobject]@{
            port = $PortName
            device_id = $deviceId
            raw_length = $offset
        }
    }
    catch {
        return $null
    }
    finally {
        if ($sp.IsOpen) { $sp.Close() }
        $sp.Dispose()
    }
}

$found = $null
foreach ($candidate in Get-CandidatePorts) {
    $result = Test-ReactionBoxPort -PortName $candidate.Port
    if ($result) {
        $found = $result
        break
    }
}

if (-not $found) {
    Write-Error '未找到反应盒'
}

if ($WriteJsonPath) {
    $dir = Split-Path -Parent $WriteJsonPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $found | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 $WriteJsonPath
}

if ($AsJson) {
    $found | ConvertTo-Json -Depth 4
} else {
    "port=$($found.port)"
    "device_id=$($found.device_id)"
    "raw_length=$($found.raw_length)"
}
