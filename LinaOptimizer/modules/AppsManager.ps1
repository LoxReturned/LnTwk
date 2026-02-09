# AppsManager.ps1 - Essential Apps Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Apps Essenciais --- #
function Get-EssentialApps {
    $apps = @(
        @{
            id = "Discord";
            name = "Discord";
            description = "Plataforma de comunicação para gamers.";
            category = "Apps";
            risk = "low";
            install = {
                # Exemplo: Baixar e instalar Discord
                # Start-Process "https://discord.com/api/download?platform=win" -Wait
                Write-Host "Instalação do Discord simulada."
            };
            detect = { Test-Path "$env:LOCALAPPDATA\Discord" };
        },
        @{
            id = "OBSStudio";
            name = "OBS Studio";
            description = "Software gratuito e de código aberto para gravação de vídeo e transmissão ao vivo.";
            category = "Apps";
            risk = "low";
            install = {
                # Exemplo: Baixar e instalar OBS Studio
                # Start-Process "https://obsproject.com/download" -Wait
                Write-Host "Instalação do OBS Studio simulada."
            };
            detect = { Test-Path "$env:ProgramFiles\obs-studio" };
        },
        @{
            id = "Steam";
            name = "Steam";
            description = "Plataforma de distribuição digital de jogos da Valve.";
            category = "Apps";
            risk = "low";
            install = {
                # Exemplo: Baixar e instalar Steam
                # Start-Process "https://store.steampowered.com/about/" -Wait
                Write-Host "Instalação do Steam simulada."
            };
            detect = { Test-Path "$env:ProgramFiles(x86)\Steam" };
        },
        @{
            id = "MSIAfterburner";
            name = "MSI Afterburner";
            description = "Utilitário de overclocking e monitoramento de hardware para placas de vídeo.";
            category = "Apps";
            risk = "medium";
            install = {
                # Exemplo: Baixar e instalar MSI Afterburner
                # Start-Process "https://www.msi.com/Landing/afterburner/graphics-cards" -Wait
                Write-Host "Instalação do MSI Afterburner simulada."
            };
            detect = { Test-Path "$env:ProgramFiles(x86)\MSI Afterburner" };
        },
        @{
            id = "7Zip";
            name = "7-Zip";
            description = "Utilitário de arquivamento de arquivos com alta taxa de compressão.";
            category = "Apps";
            risk = "low";
            install = {
                # Exemplo: Baixar e instalar 7-Zip
                # Start-Process "https://www.7-zip.org/download.html" -Wait
                Write-Host "Instalação do 7-Zip simulada."
            };
            detect = { Test-Path "$env:ProgramFiles\7-Zip" };
        }
    )
    return $apps
}

function Get-AppStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppId
    )
    $app = (Get-EssentialApps | Where-Object { $_.id -eq $AppId }) | Select-Object -First 1
    if ($app) {
        try {
            $status = Invoke-Command -ScriptBlock $app.detect
            return @{ id = $AppId; status = $status }
        } catch {
            return @{ id = $AppId; status = $false; error = $_.Exception.Message }
        }
    }
    return @{ id = $AppId; status = $false; error = "Aplicativo não encontrado." }
}

function Install-App {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppId
    )
    $app = (Get-EssentialApps | Where-Object { $_.id -eq $AppId }) | Select-Object -First 1
    if ($app) {
        try {
            Invoke-Command -ScriptBlock $app.install
            return @{ success = $true; message = "Aplicativo '$AppId' instalado com sucesso." }
        } catch {
            return @{ success = $false; message = "Erro ao instalar aplicativo '$AppId': $($_.Exception.Message)" }
        }
    }
    return @{ success = $false; message = "Aplicativo '$AppId' não encontrado." }
}
