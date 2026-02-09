# LinaOptimizer - Backup & Restore Module
# Encoding: UTF-8 with BOM

function New-RestorePoint {
    try {
        Write-Host "Verificando permissões para ponto de restauração..." -ForegroundColor Cyan
        
        # Verificar se o serviço de restauração está habilitado
        $drive = "C:\"
        $status = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        Write-Host "Criando ponto de restauração: LinaOptimizer_Backup..." -ForegroundColor Yellow
        Checkpoint-Computer -Description "LinaOptimizer_Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        return @{ success = $true; message = "Ponto de restauração criado com sucesso!" }
    } catch {
        $msg = $_.Exception.Message
        Write-Host "Erro ao criar ponto de restauração: $msg" -ForegroundColor Red
        return @{ success = $false; message = "Erro: Certifique-se de executar como Administrador e que a Proteção do Sistema está ativada no disco C:." }
    }
}
