# games.ps1 - Games Tweaks Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# Caminhos padrão de instalação de jogos
$global:GameInstallPaths = @{
    "Valorant" = @("$env:LOCALAPPDATA\Riot Games\VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe");
    "CS2" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\cs2.exe");
    "Fortnite" = @("$env:ProgramFiles\Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe");
    "Warzone" = @("$env:ProgramFiles(x86)\Call of Duty Modern Warfare\ModernWarfare.exe");
    "ApexLegends" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\Apex Legends\r5apex.exe", "$env:ProgramFiles(x86)\Origin Games\Apex Legends\r5apex.exe");
    "LoL" = @("$env:ProgramFiles(x86)\Riot Games\League of Legends\LeagueClient.exe");
    "Dota2" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\dota 2 beta\game\bin\win64\dota2.exe");
    "Minecraft" = @("$env:ProgramFiles(x86)\Minecraft Launcher\MinecraftLauncher.exe");
    "Roblox" = @("$env:LOCALAPPDATA\Roblox\Versions\version-*\RobloxPlayerBeta.exe");
    "Overwatch2" = @("$env:ProgramFiles(x86)\Overwatch\_retail_\Overwatch.exe");
    "RocketLeague" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\Rocket League\Binaries\Win64\RocketLeague.exe", "$env:ProgramFiles\Epic Games\RocketLeague\Binaries\Win64\RocketLeague.exe");
    "R6" = @("$env:ProgramFiles(x86)\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy's Rainbow Six Siege\RainbowSix.exe");
    "Cyberpunk2077" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe", "$env:ProgramFiles\GOG Galaxy\Games\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe");
    "GTAV" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe", "$env:ProgramFiles\Rockstar Games\Grand Theft Auto V\GTA5.exe");
    "PUBG" = @("$env:ProgramFiles(x86)\Steam\steamapps\common\PUBG\TslGame\Binaries\Win64\TslGame.exe");
}

# Armazenamento de caminhos customizados (persistente)
$global:CustomGamePathsFile = Join-Path $PSScriptRoot "custom_game_paths.json"
$global:CustomGamePaths = @{}

function Load-CustomGamePaths {
    if (Test-Path $global:CustomGamePathsFile) {
        $global:CustomGamePaths = (Get-Content $global:CustomGamePathsFile | ConvertFrom-Json) -as [System.Collections.Hashtable]
    }
}

function Save-CustomGamePaths {
    $global:CustomGamePaths | ConvertTo-Json -Depth 100 | Set-Content $global:CustomGamePathsFile -Encoding UTF8
}

# Carregar caminhos customizados ao iniciar o módulo
Load-CustomGamePaths

function Set-CustomGamePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GameId,
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $global:CustomGamePaths[$GameId] = $Path
    Save-CustomGamePaths
    return @{ success = $true; message = "Caminho customizado para 	'$GameId	' salvo: $Path" }
}

function Get-GameInstallPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GameId
    )

    # 1. Verificar caminho customizado
    if ($global:CustomGamePaths.ContainsKey($GameId)) {
        $customPath = $global:CustomGamePaths[$GameId]
        if (Test-Path $customPath) {
            return $customPath
        }
    }

    # 2. Verificar caminhos padrão
    if ($global:GameInstallPaths.ContainsKey($GameId)) {
        foreach ($path in $global:GameInstallPaths[$GameId]) {
            $expandedPath = Invoke-Expression "$path"
            if (Test-Path $expandedPath) {
                return $expandedPath
            }
        }
    }
    return $null
}

function Get-GameList {
    $games = @(
        @{
            id = "Valorant";
            name = "Valorant";
            icon = "fa-solid fa-crosshairs";
            processName = "VALORANT-Win64-Shipping.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        # Definir prioridade alta para o processo do Valorant
                        Get-Process -Name "VALORANT-Win64-Shipping" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        # Desativar otimizações de tela cheia
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "VALORANT-Win64-Shipping" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        # Desativar Xbox Game Bar
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        # Desativar Network Throttling
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        # Desativar HPET
                        bcdedit /set {current} useplatformclock No
                        # Desativar Dynamic Tick
                        bcdedit /set {current} disabledynamictick Yes
                        # Desativar Core Parking (exemplo simplificado)
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "CS2";
            name = "Counter-Strike 2";
            icon = "fa-solid fa-gun";
            processName = "cs2.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "cs2" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "cs2" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Fortnite";
            name = "Fortnite";
            icon = "fa-solid fa-fort-awesome";
            processName = "FortniteClient-Win64-Shipping.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "FortniteClient-Win64-Shipping" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "FortniteClient-Win64-Shipping" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Warzone";
            name = "Call of Duty: Warzone";
            icon = "fa-solid fa-skull-crossbones";
            processName = "ModernWarfare.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "ModernWarfare" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "ModernWarfare" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "ApexLegends";
            name = "Apex Legends";
            icon = "fa-solid fa-shield-virus";
            processName = "r5apex.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "r5apex" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "r5apex" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "LoL";
            name = "League of Legends";
            icon = "fa-solid fa-dragon";
            processName = "LeagueClient.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "LeagueClient" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "LeagueClient" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Dota2";
            name = "Dota 2";
            icon = "fa-solid fa-gem";
            processName = "dota2.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "dota2" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "dota2" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Minecraft";
            name = "Minecraft";
            icon = "fa-solid fa-cube";
            processName = "MinecraftLauncher.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "MinecraftLauncher" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "MinecraftLauncher" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Roblox";
            name = "Roblox";
            icon = "fa-solid fa-shapes";
            processName = "RobloxPlayerBeta.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Overwatch2";
            name = "Overwatch 2";
            icon = "fa-solid fa-robot";
            processName = "Overwatch.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "Overwatch" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "Overwatch" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "RocketLeague";
            name = "Rocket League";
            icon = "fa-solid fa-car";
            processName = "RocketLeague.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "RocketLeague" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "RocketLeague" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "R6";
            name = "Rainbow Six Siege";
            icon = "fa-solid fa-shield-halved";
            processName = "RainbowSix.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "RainbowSix" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "RainbowSix" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "Cyberpunk2077";
            name = "Cyberpunk 2077";
            icon = "fa-solid fa-city";
            processName = "Cyberpunk2077.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "Cyberpunk2077" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "Cyberpunk2077" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "GTAV";
            name = "Grand Theft Auto V";
            icon = "fa-solid fa-car-side";
            processName = "GTA5.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "GTA5" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "GTA5" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        },
        @{
            id = "PUBG";
            name = "PUBG: Battlegrounds";
            icon = "fa-solid fa-helmet-battle";
            processName = "TslGame.exe";
            profiles = @(
                @{
                    level = "light";
                    description = "Otimizações básicas para melhorar a estabilidade e FPS.";
                    apply = {
                        Get-Process -Name "TslGame" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "High" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force
                    };
                    revert = {
                        Get-Process -Name "TslGame" -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = "Normal" }
                        Set-ItemProperty -Path "HKCU:\System\GameConfigStore\Settings" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Force
                    };
                },
                @{
                    level = "medium";
                    description = "Otimizações intermediárias para um ganho notável de FPS e redução de input lag.";
                    apply = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 0 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Force
                    };
                    revert = {
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowGameBar" -Value 1 -Force
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Force
                    };
                },
                @{
                    level = "heavy";
                    description = "Otimizações agressivas para o máximo de performance, pode impactar outros apps.";
                    apply = {
                        bcdedit /set {current} useplatformclock No
                        bcdedit /set {current} disabledynamictick Yes
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 0 -Force
                    };
                    revert = {
                        bcdedit /set {current} useplatformclock Yes
                        bcdedit /set {current} disabledynamictick No
                        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82ca-495b-9a66-fd70ee552d1b\0cc5b647-c1df-4637-891a-edc233ecc92c" -Name "Value" -Value 100 -Force
                    };
                }
            );
        }
    )
    return $games
}

function Get-GameTweakStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GameId,
        [Parameter(Mandatory=$true)]
        [string]$Level
    )

    $game = (Get-GameList | Where-Object { $_.id -eq $GameId }) | Select-Object -First 1
    if (-not $game) {
        return $false
    }

    $profile = ($game.profiles | Where-Object { $_.level -eq $Level }) | Select-Object -First 1
    if (-not $profile) {
        return $false
    }

    try {
        # A detecção de tweaks de jogos é mais complexa, pois envolve múltiplos comandos.
        # Aqui, estamos apenas verificando se o processo está com prioridade alta, como exemplo.
        $process = Get-Process -Name $game.processName -ErrorAction SilentlyContinue
        if ($process) {
            return ($process.PriorityClass -eq "High")
        }
        return $false
    } catch {
        return $false
    }
}

function Apply-GameTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GameId,
        [Parameter(Mandatory=$true)]
        [string]$Level
    )

    $game = (Get-GameList | Where-Object { $_.id -eq $GameId }) | Select-Object -First 1
    if (-not $game) {
        return @{ success = $false; message = "Jogo 	'$GameId	' não encontrado." }
    }

    $profile = ($game.profiles | Where-Object { $_.level -eq $Level }) | Select-Object -First 1
    if (-not $profile) {
        return @{ success = $false; message = "Perfil 	'$Level	' não encontrado para o jogo 	'$GameId	'." }
    }

    try {
        Invoke-Command -ScriptBlock $profile.apply
        Add-TelemetryEntry -Action "ApplyGameTweak" -TweakId "$GameId-$Level" -Result "Success"
        return @{ success = $true; message = "Otimização 	'$Level	' para 	'$GameId	' aplicada com sucesso." }
    } catch {
        Add-TelemetryEntry -Action "Error" -TweakId "$GameId-$Level" -Result "Error: $($_.Exception.Message)"
        return @{ success = $false; message = "Erro ao aplicar otimização para 	'$GameId	': $($_.Exception.Message)" }
    }
}

function Revert-GameTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GameId,
        [Parameter(Mandatory=$true)]
        [string]$Level
    )

    $game = (Get-GameList | Where-Object { $_.id -eq $GameId }) | Select-Object -First 1
    if (-not $game) {
        return @{ success = $false; message = "Jogo 	'$GameId	' não encontrado." }
    }

    $profile = ($game.profiles | Where-Object { $_.level -eq $Level }) | Select-Object -First 1
    if (-not $profile) {
        return @{ success = $false; message = "Perfil 	'$Level	' não encontrado para o jogo 	'$GameId	'." }
    }

    try {
        Invoke-Command -ScriptBlock $profile.revert
        Add-TelemetryEntry -Action "RevertGameTweak" -TweakId "$GameId-$Level" -Result "Success"
        return @{ success = $true; message = "Otimização 	'$Level	' para 	'$GameId	' revertida com sucesso." }
    } catch {
        Add-TelemetryEntry -Action "Error" -TweakId "$GameId-$Level" -Result "Error: $($_.Exception.Message)"
        return @{ success = $false; message = "Erro ao reverter otimização para 	'$GameId	': $($_.Exception.Message)" }
    }
}
