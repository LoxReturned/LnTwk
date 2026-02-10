# PerformanceBrain.ps1 - Núcleo Inteligente REAL
# Encoding: UTF-8 with BOM

function Get-CimSafe {
    param(
        [Parameter(Mandatory = $true)][string]$ClassName,
        [string]$Property = "*"
    )

    try {
        return Get-CimInstance -ClassName $ClassName -ErrorAction Stop | Select-Object -Property $Property
    } catch {
        return $null
    }
}

function Get-SystemSnapshot {
    [CmdletBinding()]
    param()

    $cpu = Get-CimSafe -ClassName "Win32_Processor" | Select-Object -First 1
    $gpu = Get-CimSafe -ClassName "Win32_VideoController" | Select-Object -First 1
    $ramModules = Get-CimSafe -ClassName "Win32_PhysicalMemory"
    $ramTotalBytes = ($ramModules | Measure-Object -Property Capacity -Sum).Sum
    $disk = Get-CimSafe -ClassName "Win32_DiskDrive" | Select-Object -First 1
    $logicalDisk = Get-CimSafe -ClassName "Win32_LogicalDisk" | Where-Object { $_.DriveType -eq 3 } | Select-Object -First 1
    $os = Get-CimSafe -ClassName "Win32_OperatingSystem" | Select-Object -First 1
    $netAdapter = Get-CimSafe -ClassName "Win32_NetworkAdapter" | Where-Object { $_.PhysicalAdapter -eq $true -and $_.NetEnabled -eq $true } | Select-Object -First 1
    $battery = Get-CimSafe -ClassName "Win32_Battery" | Select-Object -First 1
    $computerSystem = Get-CimSafe -ClassName "Win32_ComputerSystem" | Select-Object -First 1

    $ramTotalGb = if ($ramTotalBytes) { [Math]::Round($ramTotalBytes / 1GB, 1) } else { 0 }
    $ramChannelGuess = if (($ramModules | Measure-Object).Count -ge 2) { "Dual (estimado)" } elseif (($ramModules | Measure-Object).Count -eq 1) { "Single (estimado)" } else { "N/A" }
    $diskType = if ($disk.MediaType -match "SSD|NVMe") { "SSD/NVMe" } elseif ($disk.Model -match "NVMe") { "NVMe" } else { "HDD/Desconhecido" }

    $snapshot = @{
        CPUName = $cpu.Name
        CPUCores = $cpu.NumberOfCores
        CPUThreads = $cpu.NumberOfLogicalProcessors
        CPUMaxClockMHz = $cpu.MaxClockSpeed
        SMTEnabled = if ($cpu.NumberOfLogicalProcessors -gt $cpu.NumberOfCores) { $true } else { $false }
        GPUName = $gpu.Name
        GPUDriverVersion = $gpu.DriverVersion
        GPUVRAMGB = if ($gpu.AdapterRAM) { [Math]::Round($gpu.AdapterRAM / 1GB, 1) } else { "N/A" }
        RAMGB = $ramTotalGb
        RAMChannel = $ramChannelGuess
        DiskModel = $disk.Model
        DiskType = $diskType
        DiskFirmware = $disk.FirmwareRevision
        DiskFreeGB = if ($logicalDisk.FreeSpace) { [Math]::Round($logicalDisk.FreeSpace / 1GB, 1) } else { "N/A" }
        OSName = $os.Caption
        WindowsBuild = $os.BuildNumber
        IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        NetworkAdapter = $netAdapter.Name
        NetworkDriver = $netAdapter.DriverVersion
        BluetoothEnabled = [bool](Get-CimSafe -ClassName "Win32_PnPEntity" | Where-Object { $_.Name -match "Bluetooth" } | Select-Object -First 1)
        IsLaptop = [bool]$battery
        BatteryStatus = if ($battery) { $battery.BatteryStatus } else { "Sem bateria" }
        Manufacturer = $computerSystem.Manufacturer
        Model = $computerSystem.Model
    }

    return $snapshot
}

function Get-HardwareClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Snapshot
    )

    $class = "MID"

    if ($Snapshot.RAMGB -lt 8 -or $Snapshot.CPUCores -lt 4) {
        $class = "LOW"
    }

    if ($Snapshot.RAMGB -ge 16 -and $Snapshot.CPUCores -ge 6 -and $Snapshot.GPUName -match "RTX|RX 6|RX 7|GTX 16|GTX 20|GTX 30|GTX 40") {
        $class = "HIGH"
    }

    if ($Snapshot.RAMGB -ge 32 -and $Snapshot.CPUCores -ge 8 -and $Snapshot.GPUName -match "RTX 30|RTX 40|RX 7") {
        $class = "EXTREME"
    }

    if ($Snapshot.DiskType -match "HDD" -and $class -ne "LOW") {
        $class = "MID"
    }

    return $class
}

function Get-SystemInfo {
    [CmdletBinding()]
    param()

    $snapshot = Get-SystemSnapshot
    $hardwareClass = Get-HardwareClass -Snapshot $snapshot

    $scoreCPU = [Math]::Min(100, (($snapshot.CPUCores * 8) + ($snapshot.CPUThreads * 2)))
    $scoreRAM = [Math]::Min(100, ($snapshot.RAMGB * 5))
    $scoreGPU = if ($snapshot.GPUName -match "RTX 40|RX 7") { 95 } elseif ($snapshot.GPUName -match "RTX|RX 6|GTX 16") { 78 } else { 55 }
    $scoreDisk = if ($snapshot.DiskType -match "NVMe") { 95 } elseif ($snapshot.DiskType -match "SSD") { 80 } else { 50 }
    $scoreNetwork = if ($snapshot.NetworkAdapter -match "Wi-Fi") { 65 } elseif ($snapshot.NetworkAdapter) { 80 } else { 50 }
    $overall = [Math]::Round((($scoreCPU + $scoreRAM + $scoreGPU + $scoreDisk + $scoreNetwork) / 5), 0)

    return @{
        os = $snapshot.OSName
        build = $snapshot.WindowsBuild
        cpu = $snapshot.CPUName
        cpuCores = $snapshot.CPUCores
        cpuThreads = $snapshot.CPUThreads
        cpuClockMHz = $snapshot.CPUMaxClockMHz
        smtEnabled = $snapshot.SMTEnabled
        gpu = $snapshot.GPUName
        gpuDriver = $snapshot.GPUDriverVersion
        gpuVramGb = $snapshot.GPUVRAMGB
        ram = "$($snapshot.RAMGB) GB"
        ramChannels = $snapshot.RAMChannel
        disk = $snapshot.DiskModel
        diskType = $snapshot.DiskType
        diskFirmware = $snapshot.DiskFirmware
        diskFreeGb = $snapshot.DiskFreeGB
        networkAdapter = $snapshot.NetworkAdapter
        networkDriver = $snapshot.NetworkDriver
        bluetooth = $snapshot.BluetoothEnabled
        isLaptop = $snapshot.IsLaptop
        battery = $snapshot.BatteryStatus
        manufacturer = $snapshot.Manufacturer
        model = $snapshot.Model
        hardwareClass = $hardwareClass
        isAdmin = $snapshot.IsAdmin
        scores = @{
            overall = $overall
            cpu = $scoreCPU
            gpu = $scoreGPU
            ram = $scoreRAM
            disk = $scoreDisk
            network = $scoreNetwork
        }
    }
}
