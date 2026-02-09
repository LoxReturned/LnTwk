# TelemetryStore.ps1 - Telemetria Local REAL
# Encoding: UTF-8 with BOM

$telemetryLogPath = Join-Path $PSScriptRoot "telemetry_log.json"

function Add-TelemetryEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Action,
        [Parameter(Mandatory=$true)]
        [string]$TweakId,
        [Parameter(Mandatory=$true)]
        [string]$Result,
        [hashtable]$MetricsBefore = @{},
        [hashtable]$MetricsAfter = @{}
    )

    $entry = @{
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        action = $Action
        tweakId = $TweakId
        result = $Result
        metricsBefore = $MetricsBefore
        metricsAfter = $MetricsAfter
    }

    $log = @()
    if (Test-Path $telemetryLogPath) {
        $log = Get-Content $telemetryLogPath | ConvertFrom-Json
    }

    $log += $entry
    $log | ConvertTo-Json -Depth 5 | Set-Content $telemetryLogPath -Encoding UTF8
}

function Get-TelemetryLog {
    [CmdletBinding()]
    param()

    if (Test-Path $telemetryLogPath) {
        return Get-Content $telemetryLogPath | ConvertFrom-Json
    }
    return @()
}
