# SafetyGuard.ps1 - Safety Guard Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Funções de Ponto de Restauração --- #
function Create-RestorePoint {
    [CmdletBinding()]
    param(
        [string]$Description = "LinaOptimizer Restore Point"
    )
    try {
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        return @{ success = $true; message = "Ponto de restauração '$Description' criado com sucesso." }
    } catch {
        return @{ success = $false; message = "Erro ao criar ponto de restauração: $($_.Exception.Message)" }
    }
}

function Get-SystemRestorePoints {
    try {
        $restorePoints = Get-ComputerRestorePoint | Select-Object SequenceNumber, CreationTime, Description, EventType, RestorePointType
        return @{ success = $true; restorePoints = $restorePoints }
    } catch {
        return @{ success = $false; message = "Erro ao obter pontos de restauração: $($_.Exception.Message)" }
    }
}

function Restore-System {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$SequenceNumber
    )
    try {
        Restore-Computer -RestorePoint $SequenceNumber
        return @{ success = $true; message = "Restauração do sistema iniciada para o ponto: $SequenceNumber. O sistema será reiniciado." }
    } catch {
        return @{ success = $false; message = "Erro ao iniciar restauração do sistema: $($_.Exception.Message)" }
    }
}

# --- Funções de Backup de Registro --- #
function Backup-RegistryKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    try {
        $parentDir = Split-Path -Path $BackupPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -Path $parentDir -ItemType Directory -Force
        }
        reg export $KeyPath $BackupPath /y
        return @{ success = $true; message = "Backup da chave '$KeyPath' criado em '$BackupPath'." }
    } catch {
        return @{ success = $false; message = "Erro ao fazer backup da chave '$KeyPath': $($_.Exception.Message)" }
    }
}

function Restore-RegistryKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    try {
        reg import $BackupPath
        return @{ success = $true; message = "Backup da chave '$BackupPath' restaurado com sucesso." }
    } catch {
        return @{ success = $false; message = "Erro ao restaurar backup da chave '$BackupPath': $($_.Exception.Message)" }
    }
}
