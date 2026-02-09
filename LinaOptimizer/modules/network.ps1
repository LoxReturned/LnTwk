# network.ps1 - Network Tweaks Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Funções Auxiliares (assumindo que são carregadas globalmente ou definidas aqui) ---
# function Test-RegistryValue { ... }
# function Set-RegistryValue { ... }
# function Remove-RegistryValue { ... }
# function Test-ServiceStatus { ... }

# --- Tweaks de Rede --- #
function Get-NetworkTweaks {
    $tweaks = @(
        @{
            id = "DisableNagleAlgorithm";
            title = "Desativar Algoritmo de Nagle";
            titleEn = "Disable Nagle's Algorithm";
            description = "Pode reduzir a latência em jogos online ao enviar pacotes menores mais rapidamente.";
            category = "Rede";
            risk = "medium";
            rebootRequired = $true;
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -Name "TcpNoDelay" -ExpectedValue 1) };
            apply = {
                Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" | ForEach-Object {
                    $interfacePath = $_.PSPath
                    Set-RegistryValue -Path $interfacePath -Name "TcpNoDelay" -Value 1 -PropertyType "DWord"
                    Set-RegistryValue -Path $interfacePath -Name "TcpAckFrequency" -Value 1 -PropertyType "DWord"
                }
            };
            revert = {
                Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" | ForEach-Object {
                    $interfacePath = $_.PSPath
                    Remove-RegistryValue -Path $interfacePath -Name "TcpNoDelay"
                    Remove-RegistryValue -Path $interfacePath -Name "TcpAckFrequency"
                }
            };
        },
        @{
            id = "EnableRSS";
            title = "Ativar RSS (Receive Side Scaling)";
            titleEn = "Enable RSS (Receive Side Scaling)";
            description = "Distribui o processamento de pacotes de rede entre vários núcleos da CPU, melhorando o desempenho.";
            category = "Rede";
            risk = "low";
            rebootRequired = $false;
            detect = { (Get-NetAdapterRss -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq $true }).Count -gt 0 };
            apply = { Enable-NetAdapterRss -Name "*" -ErrorAction SilentlyContinue };
            revert = { Disable-NetAdapterRss -Name "*" -ErrorAction SilentlyContinue };
        },
        @{
            id = "OptimizeDNSCache";
            title = "Otimizar Cache DNS";
            titleEn = "Optimize DNS Cache";
            description = "Aumenta o tamanho do cache DNS para acelerar a resolução de nomes de domínio.";
            category = "Rede";
            risk = "low";
            rebootRequired = $false;
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "CacheHashTableSize" -ExpectedValue 1024) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "CacheHashTableSize" -Value 1024 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "CacheEntryTimeLimit" -Value 600 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheEntryTtlLimit" -Value 86400 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "CacheHashTableSize"
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "CacheEntryTimeLimit"
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheEntryTtlLimit"
            };
        },
        @{
            id = "DisableIPv6";
            title = "Desativar IPv6";
            titleEn = "Disable IPv6";
            description = "Pode resolver problemas de conectividade e latência em redes que não utilizam IPv6.";
            category = "Rede";
            risk = "medium";
            rebootRequired = $true;
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -ExpectedValue 255) };
            apply = { Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 255 -PropertyType "DWord" };
            revert = { Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" };
        },
        @{
            id = "OptimizeTCPIP";
            title = "Otimizar TCP/IP";
            titleEn = "Optimize TCP/IP";
            description = "Ajusta parâmetros do TCP/IP para melhor desempenho em redes de alta velocidade.";
            category = "Rede";
            risk = "medium";
            rebootRequired = $true;
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpWindowSize" -ExpectedValue 65535) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpWindowSize" -Value 65535 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Tcp1323Opts" -Value 1 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "SackOpts" -Value 1 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Value 64 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpWindowSize"
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Tcp1323Opts"
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "SackOpts"
                Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL"
            };
        },
        @{
            id = "DisableQoSPacketScheduler";
            title = "Desativar Agendador de Pacotes QoS";
            titleEn = "Disable QoS Packet Scheduler";
            description = "Impede que o Windows reserve largura de banda para QoS, liberando para outras aplicações.";
            category = "Rede";
            risk = "low";
            rebootRequired = $true;
            detect = { (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ExpectedValue 4294967295) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex"
            };
        },
        @{
            id = "OptimizeNetworkAdapters";
            title = "Otimizar Adaptadores de Rede";
            titleEn = "Optimize Network Adapters";
            description = "Ajusta configurações avançadas dos adaptadores de rede para menor latência e maior throughput.";
            category = "Rede";
            risk = "medium";
            rebootRequired = $true;
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" -Name "*" -ExpectedValue "*" -Contains "*" ) }; # Placeholder, needs specific detection
            apply = {
                # Exemplo: Desativar Green Ethernet/Energy Efficient Ethernet
                Get-NetAdapterAdvancedProperty -DisplayName "Energy Efficient Ethernet" -ErrorAction SilentlyContinue | Where-Object Value -eq "1" | Set-NetAdapterAdvancedProperty -RegistryKeyword "*EEE" -RegistryValue 0
                # Exemplo: Ativar Jumbo Frames (se a rede suportar)
                # Get-NetAdapterAdvancedProperty -DisplayName "Jumbo Frame" -ErrorAction SilentlyContinue | Where-Object Value -eq "0" | Set-NetAdapterAdvancedProperty -RegistryKeyword "*JumboFrame" -RegistryValue 9014
            };
            revert = {
                # Reverter para padrões
                Get-NetAdapterAdvancedProperty -DisplayName "Energy Efficient Ethernet" -ErrorAction SilentlyContinue | Where-Object Value -eq "0" | Set-NetAdapterAdvancedProperty -RegistryKeyword "*EEE" -RegistryValue 1
            };
        }
    )
    return $tweaks
}

function Get-TweakStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-NetworkTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return $false
    }

    try {
        return $tweak.detect.InvokeReturnAsIs()
    } catch {
        return $false
    }
}

function Apply-Tweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-NetworkTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return @{ success = $false; message = "Tweak ID 
'$TweakId' não encontrado." }
    }

    try {
        if ($tweak.detect.InvokeReturnAsIs()) {
            # Tweak já ativo, reverter
            Invoke-Command -ScriptBlock $tweak.revert
            Add-TelemetryEntry -Action "Revert" -TweakId $TweakId -Result "Success"
            return @{ success = $true; message = "Tweak 
'$TweakId' revertido com sucesso." }
        } else {
            # Tweak inativo, aplicar
            Invoke-Command -ScriptBlock $tweak.apply
            Add-TelemetryEntry -Action "Apply" -TweakId $TweakId -Result "Success"
            return @{ success = $true; message = "Tweak 
'$TweakId' aplicado com sucesso." }
        }
    } catch {
        Add-TelemetryEntry -Action "Error" -TweakId $TweakId -Result "Error: $($_.Exception.Message)"
        return @{ success = $false; message = "Erro ao aplicar/reverter tweak 
'$TweakId': $($_.Exception.Message)" }
    }
}

function Revert-Tweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )

    $tweak = (Get-NetworkTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

    if (-not $tweak) {
        return @{ success = $false; message = "Tweak ID 
'$TweakId' não encontrado." }
    }

    try {
        Invoke-Command -ScriptBlock $tweak.revert
        Add-TelemetryEntry -Action "Revert" -TweakId $TweakId -Result "Success"
        return @{ success = $true; message = "Tweak 
'$TweakId' revertido com sucesso." }
    } catch {
        Add-TelemetryEntry -Action "Error" -TweakId $TweakId -Result "Error: $($_.Exception.Message)"
        return @{ success = $false; message = "Erro ao reverter tweak 
'$TweakId': $($_.Exception.Message)" }
    }
}
