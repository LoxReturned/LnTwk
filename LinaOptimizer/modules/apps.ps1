# LinaOptimizer - Essential Apps Module
# Encoding: UTF-8 with BOM

function Get-EssentialApps {
    return @(
        @{
            id = "discord";
            name = "Discord";
            category = "Social";
            description = "Plataforma de comunicação para gamers.";
            descriptionEn = "Communication platform for gamers.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Low";
            command = "winget install -e --id Discord.Discord --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "obs-studio";
            name = "OBS Studio";
            category = "Streaming";
            description = "Software para gravação e transmissão ao vivo.";
            descriptionEn = "Software for recording and live streaming.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Medium";
            command = "winget install -e --id OBSProject.OBSStudio --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "7zip";
            name = "7-Zip";
            category = "Utility";
            description = "Compactador de arquivos leve e eficiente.";
            descriptionEn = "Lightweight and efficient file archiver.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Low";
            command = "winget install -e --id 7zip.7zip --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "vlc";
            name = "VLC Media Player";
            category = "Media";
            description = "Reprodutor de mídia versátil.";
            descriptionEn = "Versatile media player.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Low";
            command = "winget install -e --id VideoLAN.VLC --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "steam";
            name = "Steam";
            category = "Gaming";
            description = "A maior plataforma de jogos do mundo.";
            descriptionEn = "The largest gaming platform in the world.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Medium";
            command = "winget install -e --id Valve.Steam --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "epic-games";
            name = "Epic Games Launcher";
            category = "Gaming";
            description = "Plataforma da Epic Games.";
            descriptionEn = "Epic Games platform.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Medium";
            command = "winget install -e --id EpicGames.EpicGamesLauncher --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "msi-afterburner";
            name = "MSI Afterburner";
            category = "Hardware";
            description = "Ferramenta definitiva para overclock e monitoramento.";
            descriptionEn = "Ultimate tool for overclocking and monitoring.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "High";
            command = "winget install -e --id MSI.Afterburner --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "spotify";
            name = "Spotify";
            category = "Media";
            description = "Streaming de música.";
            descriptionEn = "Music streaming.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Low";
            command = "winget install -e --id Spotify.Spotify --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "vscode";
            name = "Visual Studio Code";
            category = "Development";
            description = "Editor de código leve e poderoso.";
            descriptionEn = "Lightweight and powerful code editor.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Low";
            command = "winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements";
        },
        @{
            id = "brave";
            name = "Brave Browser";
            category = "Browser";
            description = "Navegador focado em privacidade e velocidade.";
            descriptionEn = "Privacy and speed focused browser.";
            tutorial = "Instalação silenciosa via Winget.";
            tutorialEn = "Silent installation via Winget.";
            impact = "Low";
            command = "winget install -e --id Brave.Brave --accept-package-agreements --accept-source-agreements";
        }
    )
}

function Install-App {
    param([string]$appId)
    $apps = Get-EssentialApps
    $app = $apps | Where-Object { $_.id -eq $appId }
    
    if ($app) {
        Write-Host "Instalando $($app.name)..." -ForegroundColor Cyan
        Invoke-Expression $app.command
        return @{ success = $true; message = "App $($app.name) instalado com sucesso!" }
    }
    return @{ success = $false; message = "App não encontrado." }
}
