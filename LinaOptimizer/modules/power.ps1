# power.ps1 - Power Tweaks Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Funções Auxiliares (assumindo que são carregadas globalmente ou definidas aqui) ---
# function Test-RegistryValue { ... }
# function Set-RegistryValue { ... }
# function Remove-RegistryValue { ... }
# function Test-ServiceStatus { ... }
# function Set-ServiceStatus { ... }
# function Add-TelemetryEntry { ... } # Para logs

# --- Tweaks de Energia --- #
function Get-PowerTweaks {
    $tweaks = @(
        @{
            id = "UltimatePerformancePlan";
            title = "Ativar Plano de Energia Desempenho Máximo";
            titleEn = "Enable Ultimate Performance Power Plan";
            description = "Ativa o plano de energia 'Desempenho Máximo' para otimizar a performance da CPU e GPU.";
            category = "Energia";
            tags = @("performance", "power_plan", "cpu", "gpu");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $false;
            impact = @("cpu_performance", "gpu_performance", "power_consumption");
            whatItDoes = "Configura o Windows para priorizar o desempenho em vez da economia de energia.";
            whatItDoesEn = "Configures Windows to prioritize performance over power saving.";
            enables = "Máximo desempenho da CPU e GPU, ideal para jogos e tarefas pesadas.";
            enablesEn = "Maximum CPU and GPU performance, ideal for gaming and heavy tasks.";
            disables = "Economia de energia, resultando em maior consumo de bateria/eletricidade.";
            disablesEn = "Power saving, resulting in higher battery/electricity consumption.";
            detect = {
                $guidMax = (powercfg /list | Select-String "Desempenho Máximo" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1'
                if (-not $guidMax) { $guidMax = (powercfg /list | Select-String "Ultimate Performance" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1' }
                $activeGuid = (powercfg /getactivescheme).Line -replace ".*\((.*)\).*", '$1'
                return ($activeGuid -eq $guidMax)
            };
            apply = {
                $guidMax = (powercfg /list | Select-String "Desempenho Máximo" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1'
                if (-not $guidMax) { $guidMax = (powercfg /list | Select-String "Ultimate Performance" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1' }
                if (-not $guidMax) {
                    # Ultimate Performance plan might not be enabled by default on some Windows versions
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f147494561
                    $guidMax = (powercfg /list | Select-String "Desempenho Máximo" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1'
                    if (-not $guidMax) { $guidMax = (powercfg /list | Select-String "Ultimate Performance" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1' }
                }
                if ($guidMax) { powercfg /setactive $guidMax }
            };
            revert = {
                $guidBalanced = (powercfg /list | Select-String "Equilibrado" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1'
                if (-not $guidBalanced) { $guidBalanced = (powercfg /list | Select-String "Balanced" -ErrorAction SilentlyContinue).Line -replace ".*\((.*)\).*", '$1' }
                if ($guidBalanced) { powercfg /setactive $guidBalanced }
            };
        },
        @{
            id = "DisableCPUParking";
            title = "Desativar Estacionamento de CPU";
            titleEn = "Disable CPU Parking";
            description = "Impede que o Windows desative núcleos da CPU para economizar energia, garantindo desempenho máximo.";
            category = "Energia";
            tags = @("cpu", "performance", "gaming");
            risk = "medium";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("cpu_performance", "power_consumption");
            whatItDoes = "Força todos os núcleos da CPU a permanecerem ativos, mesmo em baixa carga.";
            whatItDoesEn = "Forces all CPU cores to remain active, even under low load.";
            enables = "Máximo desempenho da CPU, ideal para jogos e aplicações que exigem todos os núcleos.";
            enablesEn = "Maximum CPU performance, ideal for games and multi-core demanding applications.";
            disables = "Economia de energia ao desativar núcleos da CPU ociosos.";
            disablesEn = "Power saving by disabling idle CPU cores.";
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\0cc5b647-c1df-4637-891a-edc2331c0c3c" -Name "Value" -ErrorAction SilentlyContinue
                return ($val.Value -eq 0)
            };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\0cc5b647-c1df-4637-891a-edc2331c0c3c" -Name "Value" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\0cc5b647-c1df-4637-891a-edc2331c0c3c" -Name "Value" -Value 100 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableCPUThrottling";
            title = "Desativar Throttling de CPU";
            titleEn = "Disable CPU Throttling";
            description = "Impede que a CPU reduza sua frequência para evitar superaquecimento, mantendo o desempenho.";
            category = "Energia";
            tags = @("cpu", "performance", "temperature");
            risk = "high";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("cpu_performance", "temperature");
            whatItDoes = "Garante que a CPU opere em sua frequência máxima sem reduções por temperatura ou energia.";
            whatItDoesEn = "Ensures the CPU operates at its maximum frequency without reductions due to temperature or power.";
            enables = "Desempenho consistente da CPU, sem quedas de frequência.";
            enablesEn = "Consistent CPU performance, without frequency drops.";
            disables = "Proteção contra superaquecimento da CPU e economia de energia.";
            disablesEn = "Protection against CPU overheating and power saving.";
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\be337238-0d82-4146-a960-4f3749d470c7" -Name "Value" -ErrorAction SilentlyContinue
                return ($val.Value -eq 0)
            };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\be337238-0d82-4146-a960-4f3749d470c7" -Name "Value" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\be337238-0d82-4146-a960-4f3749d470c7" -Name "Value" -Value 100 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableLinkStatePowerManagement";
            title = "Desativar Gerenciamento de Energia do Estado de Link";
            titleEn = "Disable Link State Power Management";
            description = "Impede que o PCIe entre em estados de baixa energia, reduzindo latência.";
            category = "Energia";
            tags = @("latency", "power_management", "pcie");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("latency", "power_consumption");
            whatItDoes = "Mantém as pistas PCIe ativas, evitando atrasos ao acessar dispositivos.";
            whatItDoesEn = "Keeps PCIe lanes active, preventing delays when accessing devices.";
            enables = "Redução de latência em dispositivos PCIe, como GPUs e SSDs NVMe.";
            enablesEn = "Reduced latency in PCIe devices, such as GPUs and NVMe SSDs.";
            disables = "Economia de energia para dispositivos PCIe.";
            disablesEn = "Power saving for PCIe devices.";
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d73-a5ee-4981-b0e6-9e36d9ab8fd1\ee12f906-d277-404b-b6da-e5fa1a576df5" -Name "Value" -ErrorAction SilentlyContinue
                return ($val.Value -eq 0)
            };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d73-a5ee-4981-b0e6-9e36d9ab8fd1\ee12f906-d277-404b-b6da-e5fa1a576df5" -Name "Value" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d73-a5ee-4981-b0e6-9e36d9ab8fd1\ee12f906-d277-404b-b6da-e5fa1a576df5" -Name "Value" -Value 1 -PropertyType "DWord"
            };
        }
    )
    return $tweaks
}

function Get-PowerTweakStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-PowerTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return $false
    }

    try {
        return $tweak.detect.InvokeReturnAsIs()
    } catch {
        return $false
    }
}

function Apply-PowerTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-PowerTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return @{ success = $false; message = "Tweak ID '$TweakId' não encontrado." }
    }

    try {
        if ($tweak.detect.InvokeReturnAsIs()) {
            # Tweak já ativo, reverter
            Invoke-Command -ScriptBlock $tweak.revert
            Add-TelemetryEntry -Action "Revert" -TweakId $TweakId -Result "Success"
            return @{ success = $true; message = "Tweak '$TweakId' revertido com sucesso." }
        } else {
            # Tweak inativo, aplicar
            Invoke-Command -ScriptBlock $tweak.apply
            Add-TelemetryEntry -Action "Apply" -TweakId $TweakId -Result "Success"
            return @{ success = $true; message = "Tweak '$TweakId' aplicado com sucesso." }
        }
    } catch {
        Add-TelemetryEntry -Action "Error" -TweakId $TweakId -Result "Error: $($_.Exception.Message)"
        return @{ success = $false; message = "Erro ao aplicar/reverter tweak '$TweakId': $($_.Exception.Message)" }
    }
}

function Revert-PowerTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-PowerTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return @{ success = $false; message = "Tweak ID '$TweakId' não encontrado." }
    }

    try {
        Invoke-Command -ScriptBlock $tweak.revert
        Add-TelemetryEntry -Action "Revert" -TweakId $TweakId -Result "Success"
        return @{ success = $true; message = "Tweak '$TweakId' revertido com sucesso." }
    } catch {
        Add-TelemetryEntry -Action "Error" -TweakId $TweakId -Result "Error: $($_.Exception.Message)"
        return @{ success = $false; message = "Erro ao reverter tweak '$TweakId': $($_.Exception.Message)" }
    }
}
