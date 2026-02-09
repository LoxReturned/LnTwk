# BenchmarkEngine.ps1 - Benchmark REAL (antes/depois)
# Encoding: UTF-8 with BOM

function Measure-Performance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Action
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-Command -ScriptBlock $Action
    $stopwatch.Stop()
    return $stopwatch.Elapsed.TotalMilliseconds
}

function Get-SystemMetrics {
    [CmdletBinding()]
    param()

    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.Where({ $_.InstanceName -eq '_Total' }).CookedValue
    $ramUsage = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples.CookedValue
    
    return @{
        CPUUsage = [Math]::Round($cpuUsage, 2)
        RAMUsage = [Math]::Round($ramUsage, 2)
        # Adicionar mais métricas conforme necessário (ex: latência de disco, rede)
    }
}

function Invoke-Benchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId,
        [Parameter(Mandatory=$true)]
        [scriptblock]$ApplyAction,
        [Parameter(Mandatory=$true)]
        [scriptblock]$RevertAction
    )

    $metricsBefore = Get-SystemMetrics
    $timeBefore = Measure-Performance -Action $ApplyAction

    # Reverter para medir o tempo de reversão, ou apenas para ter um ponto de comparação limpo
    # Invoke-Command -ScriptBlock $RevertAction

    $metricsAfter = Get-SystemMetrics
    $timeAfter = Measure-Performance -Action $ApplyAction # Medir novamente após o tweak

    return @{
        TweakId = $TweakId
        MetricsBefore = $metricsBefore
        MetricsAfter = $metricsAfter
        TimeBeforeMs = [Math]::Round($timeBefore, 2)
        TimeAfterMs = [Math]::Round($timeAfter, 2)
        # Adicionar mais resultados de benchmark conforme necessário
    }
}
