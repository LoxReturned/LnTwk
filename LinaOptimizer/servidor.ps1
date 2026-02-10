# servidor.ps1 - LinaOptimizer Web Server
# Encoding: UTF-8 with BOM

$port = 8080
$webRoot = Join-Path $PSScriptRoot "web"
$modulesPath = Join-Path $PSScriptRoot "modules"

$moduleFiles = @(
    "system.ps1",
    "network.ps1",
    "kernel.ps1",
    "power.ps1",
    "debloat.ps1",
    "games.ps1",
    "AppsManager.ps1",
    "PerformanceBrain.ps1",
    "BenchmarkEngine.ps1",
    "TelemetryStore.ps1",
    "SafetyGuard.ps1",
    "backup.ps1"
)

foreach ($moduleFile in $moduleFiles) {
    try {
        Import-Module (Join-Path $modulesPath $moduleFile) -ErrorAction Stop
        Write-Host "[INFO] Módulo $moduleFile carregado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "[ERRO] Falha ao carregar módulo ${moduleFile}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Send-HttpResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [int]$StatusCode = 200,
        [string]$ContentType = "text/html",
        [string]$Content = ""
    )

    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $Response.ContentLength64 = $buffer.Length
    $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Response.OutputStream.Close()
}

function Send-Json {
    param(
        [System.Net.HttpListenerResponse]$Response,
        $Data,
        [int]$StatusCode = 200
    )

    Send-HttpResponse -Response $Response -StatusCode $StatusCode -ContentType "application/json" -Content ($Data | ConvertTo-Json -Depth 12)
}

function Send-File {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [string]$FilePath,
        [string]$ContentType
    )

    if (-not (Test-Path $FilePath)) {
        Send-HttpResponse -Response $Response -StatusCode 404 -Content "404 Not Found"
        return
    }

    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $Response.StatusCode = 200
    $Response.ContentType = $ContentType
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

function Read-JsonBody {
    param([System.Net.HttpListenerRequest]$Request)

    $reader = New-Object System.IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
    $body = $reader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($body)) { return @{} }
    return $body | ConvertFrom-Json
}

function Try-Invoke {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [object[]]$Arguments = @(),
        [object]$Fallback = $null
    )

    if (-not (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
        Write-Host "[WARN] Comando '$Name' indisponível. Fallback aplicado." -ForegroundColor DarkYellow
        return $Fallback
    }

    try {
        return & $Name @Arguments
    } catch {
        Write-Host "[ERRO] Falha ao executar '$Name': $($_.Exception.Message)" -ForegroundColor Red
        return $Fallback
    }
}

function Get-AllTweaks {
    $all = @()

    foreach ($fn in @("Get-SystemTweaks", "Get-NetworkTweaks", "Get-KernelTweaks", "Get-PowerTweaks", "Get-DebloatTweaks")) {
        $result = Try-Invoke -Name $fn -Fallback @()
        if ($null -eq $result) { $result = @() }

        foreach ($t in @($result)) {
            $all += @{
                id = $t.id
                name = if ($t.title) { $t.title } else { $t.name }
                description = $t.description
                category = if ($t.category) { $t.category } else { "Sistema" }
                risk = if ($t.risk) {
                    switch -Regex ($t.risk.ToString().ToLower()) {
                        "high|alto" { "Alto"; break }
                        "medium|m[eé]dio" { "Médio"; break }
                        default { "Baixo" }
                    }
                } else { "Baixo" }
                status = $false
                rebootRequired = [bool]$t.needsRestart
                warning = if ($t.risk -match "high|alto") { "Tweak avançado. Use com atenção." } else { $null }
                module = $fn
                raw = $t
            }
        }
        Write-Host "[DEBUG] $fn retornou $(@($result).Count) tweaks." -ForegroundColor DarkCyan
    }

    Write-Host "[DEBUG] Total de tweaks agregados: $($all.Count)" -ForegroundColor DarkCyan
    return $all
}

function Find-TweakRawById {
    param([string]$TweakId)

    $all = Get-AllTweaks
    return ($all | Where-Object { $_.id -eq $TweakId } | Select-Object -First 1)
}

function Configure-Firewall {
    param([int]$Port)

    $ruleName = "LinaOptimizer Web Server"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host "Configurando Firewall na porta $Port..." -ForegroundColor Yellow
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
Configure-Firewall -Port $port

try {
    $listener.Start()
    Write-Host "[INFO] Servidor iniciado em http://localhost:$port" -ForegroundColor Green

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        if ($path -eq "/api/system-info" -and $method -eq "GET") {
            $info = Try-Invoke -Name "Get-SystemInfo" -Fallback @{}
            Send-Json -Response $response -Data $info
        }
        elseif ($path -eq "/api/systeminfo" -and $method -eq "GET") {
            $info = Try-Invoke -Name "Get-SystemInfo" -Fallback @{}
            Send-Json -Response $response -Data @{ systemInfo = $info }
        }
        elseif ($path -eq "/api/hardware-info" -and $method -eq "GET") {
            $info = Try-Invoke -Name "Get-SystemInfo" -Fallback @{}
            Send-Json -Response $response -Data $info
        }
        elseif ($path -eq "/api/tweaks" -and $method -eq "GET") {
            Send-Json -Response $response -Data @{ tweaks = (Get-AllTweaks) }
        }
        elseif ($path -eq "/api/tweak-status" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $entry = Find-TweakRawById -TweakId $data.tweakId
            if (-not $entry) {
                Send-Json -Response $response -StatusCode 404 -Data @{ id = $data.tweakId; status = $false; error = "Tweak não encontrado." }
            } else {
                try {
                    $status = [bool](Invoke-Command -ScriptBlock $entry.raw.detect)
                    Send-Json -Response $response -Data @{ id = $data.tweakId; status = $status }
                } catch {
                    Send-Json -Response $response -Data @{ id = $data.tweakId; status = $false; error = $_.Exception.Message }
                }
            }
        }
        elseif ($path -eq "/api/apply-tweak" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $entry = Find-TweakRawById -TweakId $data.tweakId
            if (-not $entry) {
                Send-Json -Response $response -StatusCode 404 -Data @{ success = $false; message = "Tweak não encontrado." }
            } else {
                try {
                    Invoke-Command -ScriptBlock $entry.raw.apply
                    Send-Json -Response $response -Data @{ success = $true; message = "Tweak aplicado com sucesso." }
                } catch {
                    Send-Json -Response $response -Data @{ success = $false; message = $_.Exception.Message }
                }
            }
        }
        elseif ($path -eq "/api/revert-tweak" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $entry = Find-TweakRawById -TweakId $data.tweakId
            if (-not $entry) {
                Send-Json -Response $response -StatusCode 404 -Data @{ success = $false; message = "Tweak não encontrado." }
            } else {
                try {
                    Invoke-Command -ScriptBlock $entry.raw.revert
                    Send-Json -Response $response -Data @{ success = $true; message = "Tweak revertido com sucesso." }
                } catch {
                    Send-Json -Response $response -Data @{ success = $false; message = $_.Exception.Message }
                }
            }
        }
        elseif ($path -eq "/api/games" -and $method -eq "GET") {
            $games = Try-Invoke -Name "Get-GameList" -Fallback @()
            $gameDtos = @()
            foreach ($game in @($games)) {
                $gameDtos += @{
                    id = $game.id
                    name = $game.name
                    description = "Perfis de otimização de jogo"
                    detected = [bool](Try-Invoke -Name "Get-GameInstallPath" -Arguments @($game.id) -Fallback $null)
                }
            }
            Write-Host "[DEBUG] Get-GameList retornou $($gameDtos.Count) jogos." -ForegroundColor DarkCyan
            Send-Json -Response $response -Data @{ games = $gameDtos }
        }
        elseif ($path -eq "/api/apply-game-tweak" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $level = if ($data.intensity) { $data.intensity } else { "medium" }
            $result = Try-Invoke -Name "Apply-GameTweak" -Arguments @($data.gameId, $level) -Fallback @{ success = $false; message = "Função indisponível" }
            Send-Json -Response $response -Data $result
        }
        elseif ($path -eq "/api/apps" -and $method -eq "GET") {
            $apps = Try-Invoke -Name "Get-EssentialApps" -Fallback @()
            $appDtos = @()
            foreach ($app in @($apps)) {
                $installed = $false
                try { $installed = [bool](Invoke-Command -ScriptBlock $app.detect) } catch { $installed = $false }
                $appDtos += @{
                    id = $app.id
                    name = $app.name
                    description = $app.description
                    icon = "📦"
                    installed = $installed
                }
            }
            Write-Host "[DEBUG] Get-EssentialApps retornou $($appDtos.Count) apps." -ForegroundColor DarkCyan
            Send-Json -Response $response -Data @{ apps = $appDtos }
        }
        elseif ($path -eq "/api/app-status" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $result = Try-Invoke -Name "Get-AppStatus" -Arguments @($data.appId) -Fallback @{ id = $data.appId; status = $false }
            Send-Json -Response $response -Data $result
        }
        elseif ($path -eq "/api/install-app" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $result = Try-Invoke -Name "Install-App" -Arguments @($data.appId) -Fallback @{ success = $false; message = "Função indisponível" }
            Send-Json -Response $response -Data $result
        }
        elseif ($path -eq "/api/create-restore-point" -and $method -eq "POST") {
            $result = Try-Invoke -Name "Create-RestorePoint" -Fallback @{ success = $false; message = "Função indisponível" }
            Send-Json -Response $response -Data $result
        }
        elseif ($path -eq "/api/benchmark" -and $method -eq "POST") {
            $data = Read-JsonBody -Request $request
            $result = Try-Invoke -Name "Run-Benchmark" -Arguments @($data.type) -Fallback @{ success = $false; message = "Função indisponível" }
            Send-Json -Response $response -Data $result
        }
        else {
            $filePath = Join-Path $webRoot $path
            if ($path -eq "/") { $filePath = Join-Path $webRoot "index.html" }

            $contentType = switch ([System.IO.Path]::GetExtension($filePath).ToLower()) {
                ".html" { "text/html" }
                ".css" { "text/css" }
                ".js" { "application/javascript" }
                ".json" { "application/json" }
                ".png" { "image/png" }
                ".jpg" { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".gif" { "image/gif" }
                ".ico" { "image/x-icon" }
                default { "application/octet-stream" }
            }
            Send-File -Response $response -FilePath $filePath -ContentType $contentType
        }
    }
}
catch {
    Write-Host "[ERRO CRÍTICO] $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        $listener.Close()
    }
    Write-Host "[INFO] Servidor finalizado." -ForegroundColor DarkRed
}
