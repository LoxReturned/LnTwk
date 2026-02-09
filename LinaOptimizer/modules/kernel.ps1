# kernel.ps1 - Kernel Tweaks Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

function Get-KernelTweaks {
    $tweaks = @(
        @{
            id = "DisableHPET"
            title = "Desativar HPET (High Precision Event Timer)"
            titleEn = "Disable HPET (High Precision Event Timer)"
            category = "Kernel"
            tags = @("latency", "kernel", "timer", "gaming")
            risk = "medium"
            needsAdmin = $true
            needsRestart = $true
            impact = @("latency")
            whatItDoes = "Desativa o HPET, que pode introduzir latência em alguns sistemas, especialmente em jogos, usando o TSC como timer principal."
            whatItDoesEn = "Disables HPET, which can introduce latency in some systems, especially in games, using TSC as the primary timer."
            enables = "Potencial redução de latência e melhor consistência de frametimes em jogos."
            enablesEn = "Potential reduction in latency and better frametime consistency in games."
            disables = "Uso do timer de alta precisão do sistema, que pode ser menos preciso para jogos."
            disablesEn = "Use of the system's high-precision timer, which can be less precise for games."
            detect = {
                $val = (bcdedit /enum {current} | Select-String "useplatformclock" -ErrorAction SilentlyContinue).Line
                return ($val -match "Yes")
            }
            apply = {
                bcdedit /set {current} useplatformclock Yes
            }
            revert = {
                bcdedit /deletevalue {current} useplatformclock
            }
        },
        @{
            id = "DisableDynamicTick"
            title = "Desativar Dynamic Tick"
            titleEn = "Disable Dynamic Tick"
            category = "Kernel"
            tags = @("latency", "kernel", "timer", "power")
            risk = "medium"
            needsAdmin = $true
            needsRestart = $true
            impact = @("latency", "power_consumption")
            whatItDoes = "Desativa o Dynamic Tick, que ajusta a frequência do timer do sistema para economizar energia, melhorando a consistência."
            whatItDoesEn = "Disables Dynamic Tick, which adjusts the system timer frequency to save power, improving consistency."
            enables = "Melhora a consistência do timer do sistema, reduzindo latência em jogos e aplicações sensíveis."
            enablesEn = "Improves system timer consistency, reducing latency in games and sensitive applications."
            disables = "Economia de energia do processador através do ajuste dinâmico do timer."
            disablesEn = "Processor power saving through dynamic timer adjustment."
            detect = {
                $val = (bcdedit /enum {current} | Select-String "disabledynamictick" -ErrorAction SilentlyContinue).Line
                return ($val -match "Yes")
            }
            apply = {
                bcdedit /set {current} disabledynamictick Yes
            }
            revert = {
                bcdedit /deletevalue {current} disabledynamictick
            }
        },
        @{
            id = "DisableCoreParking"
            title = "Desativar Core Parking"
            titleEn = "Disable Core Parking"
            category = "Kernel"
            tags = @("cpu", "performance", "gaming")
            risk = "high"
            needsAdmin = $true
            needsRestart = $true
            impact = @("cpu_performance", "power_consumption")
            whatItDoes = "Desativa o Core Parking, forçando todos os núcleos da CPU a ficarem ativos, melhorando a performance em cargas de trabalho intensas."
            whatItDoesEn = "Disables Core Parking, forcing all CPU cores to remain active, improving performance under intense workloads."
            enables = "Uso total da capacidade da CPU, ideal para jogos e aplicações que exigem muitos núcleos."
            enablesEn = "Full utilization of CPU capacity, ideal for games and multi-core demanding applications."
            disables = "Economia de energia ao 'estacionar' núcleos da CPU quando não estão em uso."
            disablesEn = "Power saving by 'parking' CPU cores when not in use."
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\0cc5b647-c1df-4637-891a-edc2331c0c3c" -Name "Value" -ErrorAction SilentlyContinue
                return ($val.Value -eq 0)
            }
            apply = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\0cc5b647-c1df-4637-891a-edc2331c0c3c" -Name "Value" -Value 0 -Force
            }
            revert = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495a-9b76-ee6f346f317f\0cc5b647-c1df-4637-891a-edc2331c0c3c" -Name "Value" -Value 100 -Force
            }
        },
        @{
            id = "OptimizeInterruptPolicy"
            title = "Otimizar Política de Interrupção"
            titleEn = "Optimize Interrupt Policy"
            category = "Kernel"
            tags = @("latency", "cpu", "irq")
            risk = "high"
            needsAdmin = $true
            needsRestart = $true
            impact = @("latency")
            whatItDoes = "Ajusta a prioridade de interrupções do sistema para reduzir latência e melhorar a resposta a eventos de hardware."
            whatItDoesEn = "Adjusts system interrupt priority to reduce latency and improve response to hardware events."
            enables = "Respostas mais rápidas do sistema a eventos de hardware, crucial para jogos e áudio."
            enablesEn = "Faster system responses to hardware events, crucial for gaming and audio."
            disables = "Gerenciamento padrão de interrupções, que pode introduzir micro-latências."
            disablesEn = "Default interrupt management, which can introduce micro-latencies."
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue
                return ($val.Win32PrioritySeparation -eq 26)
            }
            apply = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26 -Force
            }
            revert = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2 -Force
            }
        },
        @{
            id = "DisableSpectreMeltdown"
            title = "Desativar Mitigações Spectre/Meltdown"
            titleEn = "Disable Spectre/Meltdown Mitigations"
            category = "Kernel"
            tags = @("performance", "security", "cpu")
            risk = "extreme"
            needsAdmin = $true
            needsRestart = $true
            impact = @("fps", "latency", "security")
            whatItDoes = "Desativa as mitigações de segurança para Spectre e Meltdown, que podem reduzir a performance da CPU em até 30%."
            whatItDoesEn = "Disables security mitigations for Spectre and Meltdown, which can reduce CPU performance by up to 30%."
            enables = "Potencial aumento significativo de performance da CPU, ideal para sistemas onde a segurança física é garantida."
            enablesEn = "Potential significant increase in CPU performance, ideal for systems where physical security is guaranteed."
            disables = "Proteção contra vulnerabilidades de execução especulativa, aumentando o risco de ataques."
            disablesEn = "Protection against speculative execution vulnerabilities, increasing the risk of attacks."
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
                return ($val.FeatureSettingsOverride -eq 3)
            }
            apply = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -Value 3 -Force
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -Value 3 -Force
            }
            revert = {
                Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -ErrorAction SilentlyContinue
            }
        },
        @{
            id = "DisableVirtualizationBasedSecurity"
            title = "Desativar Segurança Baseada em Virtualização (VBS)"
            titleEn = "Disable Virtualization-Based Security (VBS)"
            category = "Kernel"
            tags = @("security", "performance", "gaming")
            risk = "high"
            needsAdmin = $true
            needsRestart = $true
            impact = @("fps", "latency", "security")
            whatItDoes = "Desativa o VBS, que usa virtualização para isolar partes do sistema, mas pode impactar a performance em jogos."
            whatItDoesEn = "Disables VBS, which uses virtualization to isolate parts of the system, but can impact gaming performance."
            enables = "Potencial aumento de FPS e redução de latência em jogos, liberando recursos da CPU."
            enablesEn = "Potential increase in FPS and reduction in latency in games, freeing up CPU resources."
            disables = "Recursos de segurança avançados como Integridade de Código Protegida por Hypervisor (HVCI)."
            disablesEn = "Advanced security features like Hypervisor-Protected Code Integrity (HVCI)."
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -ErrorAction SilentlyContinue
                return ($val.EnableVirtualizationBasedSecurity -eq 0)
            }
            apply = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -Force
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "RequirePlatformSecurityFeatures" -Value 0 -Force
            }
            revert = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 1 -Force
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "RequirePlatformSecurityFeatures" -Value 1 -Force
            }
        },
        @{
            id = "DisableMemoryIntegrity"
            title = "Desativar Integridade de Memória (HVCI)"
            titleEn = "Disable Memory Integrity (HVCI)"
            category = "Kernel"
            tags = @("security", "performance", "gaming")
            risk = "high"
            needsAdmin = $true
            needsRestart = $true
            impact = @("fps", "latency", "security")
            whatItDoes = "Desativa a Integridade de Memória (HVCI), que protege contra injeção de código malicioso, mas pode impactar a performance."
            whatItDoesEn = "Disables Memory Integrity (HVCI), which protects against malicious code injection, but can impact performance."
            enables = "Potencial aumento de FPS e redução de latência em jogos, liberando recursos da CPU."
            enablesEn = "Potential increase in FPS and reduction in latency in games, freeing up CPU resources."
            disables = "Proteção avançada contra injeção de código malicioso na memória."
            disablesEn = "Advanced protection against malicious code injection into memory."
            detect = {
                $val = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -ErrorAction SilentlyContinue
                return ($val.Enabled -eq 0)
            }
            apply = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -Force
            }
            revert = {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -Force
            }
        }
    )
    return $tweaks
}

function Apply-Tweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-KernelTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

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

function Get-TweakStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-KernelTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return $false
    }

    try {
        return $tweak.detect.InvokeReturnAsIs()
    } catch {
        return $false
    }
}
