# debloat.ps1 - Debloat Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Funções Auxiliares (reutilizadas do system.ps1) ---
# (Assumindo que estas funções são carregadas globalmente ou que debloat.ps1 as define também)
# function Test-RegistryValue { ... }
# function Set-RegistryValue { ... }
# function Remove-RegistryValue { ... }
# function Test-ServiceStatus { ... }
# function Set-ServiceStatus { ... }

# --- Tweaks de Debloat --- #
function Get-DebloatTweaks {
    $tweaks = @(
        @{
            id = "RemoveOneDrive";
            name = "Remover OneDrive";
            description = "Desinstala completamente o OneDrive do sistema.";
            category = "Debloat";
            risk = "medium";
            rebootRequired = $true;
            detect = { -not (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive") };
            apply = {
                if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
                    & "$env:SystemRoot\System32\OneDriveSetup.exe" /uninstall
                }
                if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
                    & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
                }
            };
            revert = {
                # Reinstalar OneDrive (requer o instalador)
                # Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" /silent
                Write-Host "Reinstalação do OneDrive requer download manual ou instalador." -ForegroundColor Yellow
            };
        },
        @{
            id = "RemoveXboxApps";
            name = "Remover Aplicativos Xbox";
            description = "Desinstala todos os aplicativos relacionados ao Xbox (Game Bar, Console Companion, etc.).";
            category = "Debloat";
            risk = "low";
            rebootRequired = $false;
            detect = { (Get-AppxPackage -Name "*xbox*" -ErrorAction SilentlyContinue).Count -eq 0 };
            apply = {
                Get-AppxPackage -Name "*xbox*" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            };
            revert = {
                # Reinstalar Xbox Apps (requer loja ou instalador)
                Write-Host "Reinstalação dos Apps Xbox requer loja ou instalador." -ForegroundColor Yellow
            };
        },
        @{
            id = "RemoveCortanaApp";
            name = "Remover Aplicativo Cortana";
            description = "Desinstala o aplicativo Cortana do sistema.";
            category = "Debloat";
            risk = "low";
            rebootRequired = $false;
            detect = { (Get-AppxPackage -Name "*Microsoft.Windows.Cortana*" -ErrorAction SilentlyContinue).Count -eq 0 };
            apply = {
                Get-AppxPackage -Name "*Microsoft.Windows.Cortana*" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            };
            revert = {
                # Reinstalar Cortana (requer loja ou instalador)
                Write-Host "Reinstalação do Cortana requer loja ou instalador." -ForegroundColor Yellow
            };
        },
        @{
            id = "RemoveEdge";
            name = "Remover Microsoft Edge";
            description = "Desinstala o navegador Microsoft Edge. Não recomendado se for seu navegador principal.";
            category = "Debloat";
            risk = "high";
            rebootRequired = $true;
            detect = { -not (Test-Path "$env:ProgramFiles(x86)\Microsoft\Edge") };
            apply = {
                $edgePath = Get-Item "$env:ProgramFiles(x86)\Microsoft\Edge\Application\*" | Where-Object {$_.PSIsContainer -and $_.Name -match "^\d+\.\d+\.\d+\.\d+$"}
                if ($edgePath) {
                    & "$edgePath\Installer\setup.exe" --uninstall --system-level --verbose-logging --force-uninstall
                }
            };
            revert = {
                Write-Host "Reinstalação do Microsoft Edge requer download manual." -ForegroundColor Yellow
            };
        },
        @{
            id = "RemoveBuiltinApps";
            name = "Remover Apps Nativos (Fotos, Filmes, etc.)";
            description = "Desinstala vários aplicativos nativos do Windows (Fotos, Filmes e TV, Groove Música, etc.).";
            category = "Debloat";
            risk = "medium";
            rebootRequired = $false;
            detect = { (Get-AppxPackage -Name "*ZuneMusic*" -ErrorAction SilentlyContinue).Count -eq 0 -and (Get-AppxPackage -Name "*ZuneVideo*" -ErrorAction SilentlyContinue).Count -eq 0 };
            apply = {
                $appsToRemove = @(
                    "*ZuneMusic*", "*ZuneVideo*", "*Microsoft.Windows.Photos*", "*Microsoft.BingWeather*",
                    "*Microsoft.Windows.Maps*", "*Microsoft.GetHelp*", "*Microsoft.Getstarted*",
                    "*Microsoft.MicrosoftSolitaireCollection*", "*Microsoft.WindowsFeedbackHub*",
                    "*Microsoft.Xbox.TCUI*", "*Microsoft.XboxApp*", "*Microsoft.XboxGameOverlay*",
                    "*Microsoft.XboxGamingOverlay*", "*Microsoft.XboxIdentityProvider*", "*Microsoft.XboxSpeechToTextOverlay*",
                    "*Microsoft.YourPhone*", "*Microsoft.SkypeApp*", "*Microsoft.MixedReality.Portal*",
                    "*Microsoft.WindowsAlarms*", "*Microsoft.WindowsCalculator*", "*Microsoft.WindowsCamera*",
                    "*Microsoft.WindowsSoundRecorder*", "*Microsoft.People*", "*Microsoft.StickyNotes*",
                    "*Microsoft.Print3D*", "*Microsoft.Paint3D*", "*Microsoft.ScreenSketch*",
                    "*Microsoft.Wallet*", "*Microsoft.WebMediaExtensions*", "*Microsoft.HEVCVideoExtension*"
                )
                foreach ($app in $appsToRemove) {
                    Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
                }
            };
            revert = {
                Write-Host "Reinstalação de apps nativos requer loja ou instalador." -ForegroundColor Yellow
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
    $tweak = (Get-DebloatTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1
    if ($tweak) {
        try {
            $status = Invoke-Command -ScriptBlock $tweak.detect
            return @{ id = $TweakId; status = $status }
        } catch {
            return @{ id = $TweakId; status = $false; error = $_.Exception.Message }
        }
    }
    return @{ id = $TweakId; status = $false; error = "Tweak não encontrado." }
}

function Apply-Tweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )
    $tweak = (Get-DebloatTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1
    if ($tweak) {
        try {
            Invoke-Command -ScriptBlock $tweak.apply
            return @{ success = $true; message = "Tweak \'$TweakId\' aplicado com sucesso." }
        } catch {
            return @{ success = $false; message = "Erro ao aplicar tweak \'$TweakId\': $($_.Exception.Message)" }
        }
    }
    return @{ success = $false; message = "Tweak \'$TweakId\' não encontrado." }
}

function Revert-Tweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TweakId
    )
    $tweak = (Get-DebloatTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1
    if ($tweak) {
        try {
            Invoke-Command -ScriptBlock $tweak.revert
            return @{ success = $true; message = "Tweak \'$TweakId\' revertido com sucesso." }
        } catch {
            return @{ success = $false; message = "Erro ao reverter tweak \'$TweakId\': $($_.Exception.Message)" }
        }
    }
    return @{ success = $false; message = "Tweak \'$TweakId\' não encontrado." }
}
