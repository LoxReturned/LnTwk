# PerformanceBrain.ps1 - Núcleo Inteligente REAL
# Encoding: UTF-8 with BOM

function Get-SystemSnapshot {
    [CmdletBinding()]
    param()

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $ram = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB
    $disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -First 1
    $os = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1

    $snapshot = @{
        CPUName = $cpu.Name
        CPUCores = $cpu.NumberOfCores
        CPUThreads = $cpu.NumberOfLogicalProcessors
        GPUName = $gpu.Name
        RAMGB = [Math]::Round($ram)
        DiskType = if ($disk.MediaType -eq 12) { "SSD" } else { "HDD" } # 12 for SSD, 0 for HDD (generic)
        WindowsBuild = $os.BuildNumber
        IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    return $snapshot
}

function Get-HardwareClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Snapshot
    )

    $class = "MID"

    # Regras para LOW
    if ($Snapshot.RAMGB -lt 8 -or $Snapshot.CPUCores -lt 4) {
        $class = "LOW"
    }
    # Regras para HIGH
    if ($Snapshot.RAMGB -ge 16 -and $Snapshot.CPUCores -ge 6 -and $Snapshot.GPUName -match "RTX|RX 6|RX 7|GTX 16|GTX 20|GTX 30|GTX 40") {
        $class = "HIGH"
    }
    # Regras para EXTREME
    if ($Snapshot.RAMGB -ge 32 -and $Snapshot.CPUCores -ge 8 -and $Snapshot.GPUName -match "RTX 30|RTX 40|RX 7") {
        $class = "EXTREME"
    }

    # Ajuste se for HDD
    if ($Snapshot.DiskType -eq "HDD" -and $class -ne "LOW") {
        $class = "MID" # Reduz a classe se for HDD e não for LOW
    }

    return $class
}

function Get-SystemInfo {
    [CmdletBinding()]
    param()

    $snapshot = Get-SystemSnapshot
    $hardwareClass = Get-HardwareClass -Snapshot $snapshot

    $info = @{
        os = (Get-CimInstance Win32_OperatingSystem).Caption
        cpu = $snapshot.CPUName
        gpu = $snapshot.GPUName
        ram = "$($snapshot.RAMGB) GB"
        hardwareClass = $hardwareClass
        isAdmin = $snapshot.IsAdmin
    }
    return $info
}
