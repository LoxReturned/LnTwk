# servidor.ps1 - LinaOptimizer Web Server - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Configurações --- #
$port = 8080
$webRoot = Join-Path $PSScriptRoot "web"
$modulesPath = Join-Path $PSScriptRoot "modules"

# --- Carregar Módulos PowerShell --- #
$moduleFiles = @("system.ps1", "network.ps1", "kernel.ps1", "games.ps1", "AppsManager.ps1", "power.ps1", "PerformanceBrain.ps1", "BenchmarkEngine.ps1", "TelemetryStore.ps1", "SafetyGuard.ps1")
foreach ($moduleFile in $moduleFiles) {
    try {
        Import-Module (Join-Path $modulesPath $moduleFile) -ErrorAction Stop
        Write-Host "[INFO] Módulo $moduleFile carregado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "[ERRO] Falha ao carregar módulo ${moduleFile}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Funções Auxiliares para o Servidor --- #
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
        $Data
    )
    Send-HttpResponse -Response $Response -StatusCode 200 -ContentType "application/json" -Content ($Data | ConvertTo-Json -Depth 10)
}

function Send-File {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [string]$FilePath,
        [string]$ContentType
    )
    if (Test-Path $FilePath) {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $Response.StatusCode = 200
        $Response.ContentType = $ContentType
        $Response.ContentLength64 = $bytes.Length
        $Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $Response.OutputStream.Close()
    } else {
        Send-HttpResponse -Response $Response -StatusCode 404 -Content "404 Not Found"
    }
}

# --- Configurar Firewall para Acesso Remoto --- #
function Configure-Firewall {
    param(
        [int]$Port
    )
    $ruleName = "LinaOptimizer Web Server"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host "Configurando Firewall para permitir acesso na porta $Port..." -ForegroundColor Yellow
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow -Enabled True -ErrorAction SilentlyContinue
        Write-Host "Regra de Firewall criada com sucesso." -ForegroundColor Green
    } else {
        Write-Host "Regra de Firewall já existe." -ForegroundColor DarkYellow
    }
}

# --- Iniciar Servidor --- #
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")

Configure-Firewall -Port $port

try {
    $listener.Start()
    $ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString
    Write-Host "[$(Get-Date)] [INFO] Motor a vapor iniciado!" -ForegroundColor Green
    Write-Host "Acesse localmente: http://localhost:$port" -ForegroundColor Cyan
    Write-Host "Acesse na rede: http://${ip}:$port" -ForegroundColor Cyan

    # Abrir navegador automaticamente
    Start-Process "http://localhost:$port"

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        # --- Rotas da API --- #
        if ($path -eq "/api/system-info" -and $method -eq "GET") {
            Send-Json -Response $response -Data (Get-SystemInfo)
        } elseif ($path -eq "/api/tweaks" -and $method -eq "GET") {
            $systemTweaks = @()
            try { $systemTweaks = Get-SystemTweaks } catch { Write-Host "[ERRO] Falha ao obter SystemTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-SystemTweaks retornou $($systemTweaks.Count) tweaks." -ForegroundColor DarkCyan

            $networkTweaks = @()
            try { $networkTweaks = Get-NetworkTweaks } catch { Write-Host "[ERRO] Falha ao obter NetworkTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-NetworkTweaks retornou $($networkTweaks.Count) tweaks." -ForegroundColor DarkCyan

            $kernelTweaks = @()
            try { $kernelTweaks = Get-KernelTweaks } catch { Write-Host "[ERRO] Falha ao obter KernelTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-KernelTweaks retornou $($kernelTweaks.Count) tweaks." -ForegroundColor DarkCyan

            $powerTweaks = @()
            try { $powerTweaks = Get-PowerTweaks } catch { Write-Host "[ERRO] Falha ao obter PowerTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-PowerTweaks retornou $($powerTweaks.Count) tweaks." -ForegroundColor DarkCyan

            $debloatTweaks = @()
            try { $debloatTweaks = Get-DebloatTweaks } catch { Write-Host "[ERRO] Falha ao obter DebloatTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-DebloatTweaks retornou $($debloatTweaks.Count) tweaks." -ForegroundColor DarkCyan

            $safetyGuardTweaks = @()
            try { $safetyGuardTweaks = Get-SafetyGuardTweaks } catch { Write-Host "[ERRO] Falha ao obter SafetyGuardTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-SafetyGuardTweaks retornou $($safetyGuardTweaks.Count) tweaks." -ForegroundColor DarkCyan

            $allTweaks = @(
                $systemTweaks,
                $networkTweaks,
                $kernelTweaks,
                $powerTweaks,
                $debloatTweaks,
                $safetyGuardTweaks
            ) | Select-Object -ExpandProperty *
            Write-Host "[DEBUG] Total de tweaks agregados: $($allTweaks.Count)" -ForegroundColor DarkCyan
            Send-Json -Response $response -Data @{ tweaks = $allTweaks }
        } elseif ($path -eq "/api/tweak-status" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $tweakId = $data.tweakId
            $module = $data.module

            $status = $false
            switch ($module) {
                "System" { $status = Get-SystemTweakStatus -TweakId $tweakId }
                "Network" { $status = Get-NetworkTweakStatus -TweakId $tweakId }
                "Kernel" { $status = Get-KernelTweakStatus -TweakId $tweakId }
                "Power" { $status = Get-PowerTweakStatus -TweakId $tweakId }
                "Debloat" { $status = Get-DebloatTweakStatus -TweakId $tweakId }
                "Safety" { $status = Get-SafetyGuardTweakStatus -TweakId $tweakId }
            }
            Send-Json -Response $response -Data @{ id = $tweakId; status = $status }
        } elseif ($path -eq "/api/apply-tweak" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $tweakId = $data.tweakId
            $module = $data.module

            $result = @{ success = $false; message = "Módulo não encontrado." }
            switch ($module) {
                "System" { $result = Apply-SystemTweak -TweakId $tweakId }
                "Network" { $result = Apply-NetworkTweak -TweakId $tweakId }
                "Kernel" { $result = Apply-KernelTweak -TweakId $tweakId }
                "Power" { $result = Apply-PowerTweak -TweakId $tweakId }
                "Debloat" { $result = Apply-DebloatTweak -TweakId $tweakId }
                "Safety" { $result = Apply-SafetyGuardTweak -TweakId $tweakId }
            }
            Send-Json -Response $response -Data $result
        } elseif ($path -eq "/api/revert-tweak" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $tweakId = $data.tweakId
            $module = $data.module

            $result = @{ success = $false; message = "Módulo não encontrado." }
            switch ($module) {
                "System" { $result = Revert-SystemTweak -TweakId $tweakId }
                "Network" { $result = Revert-NetworkTweak -TweakId $tweakId }
                "Kernel" { $result = Revert-KernelTweak -TweakId $tweakId }
                "Power" { $result = Revert-PowerTweak -TweakId $tweakId }
                "Debloat" { $result = Revert-DebloatTweak -TweakId $tweakId }
                "Safety" { $result = Revert-SafetyGuardTweak -TweakId $tweakId }
            }
            Send-Json -Response $response -Data $result
        } elseif ($path -eq "/api/games" -and $method -eq "GET") {
            $gameTweaks = @()
            try { $gameTweaks = Get-GameTweaks } catch { Write-Host "[ERRO] Falha ao obter GameTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-GameTweaks retornou $($gameTweaks.Count) jogos." -ForegroundColor DarkCyan
            Send-Json -Response $response -Data @{ games = $gameTweaks }
        } elseif ($path -eq "/api/game-status" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $gameId = $data.gameId
            Send-Json -Response $response -Data (Get-GameStatus -GameId $gameId)
        } elseif ($path -eq "/api/apply-game-tweak" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $gameId = $data.gameId
            $intensity = $data.intensity
            Send-Json -Response $response -Data (Apply-GameTweak -GameId $gameId -Intensity $intensity)
        } elseif ($path -eq "/api/set-game-path" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $gameId = $data.gameId
            $path = $data.path
            Send-Json -Response $response -Data (Set-GamePath -GameId $gameId -Path $path)
        } elseif ($path -eq "/api/apps" -and $method -eq "GET") {
            $appTweaks = @()
            try { $appTweaks = Get-AppsManagerTweaks } catch { Write-Host "[ERRO] Falha ao obter AppsManagerTweaks: $($_.Exception.Message)" -ForegroundColor Red }
            Write-Host "[DEBUG] Get-AppsManagerTweaks retornou $($appTweaks.Count) apps." -ForegroundColor DarkCyan
            Send-Json -Response $response -Data @{ apps = $appTweaks }
        } elseif ($path -eq "/api/app-status" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $appId = $data.appId
            Send-Json -Response $response -Data (Get-AppsManagerTweakStatus -AppId $appId)
        } elseif ($path -eq "/api/install-app" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $appId = $data.appId
            Send-Json -Response $response -Data (Apply-AppsManagerTweak -TweakId $appId)
        } elseif ($path -eq "/api/create-restore-point" -and $method -eq "POST") {
            Send-Json -Response $response -Data (Create-RestorePoint)
        } elseif ($path -eq "/api/systeminfo" -and $method -eq "GET") {
            Send-Json -Response $response -Data @{ systemInfo = (Get-SystemInfo) }
        } elseif ($path -eq "/api/hardware-info" -and $method -eq "GET") {
            Send-Json -Response $response -Data (Get-SystemInfo)
        } elseif ($path -eq "/api/benchmark" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $type = $data.type # 'cpu', 'ram', 'disk'
            Send-Json -Response $response -Data (Run-Benchmark -Type $type)
        } elseif ($path -eq "/api/telemetry" -and $method -eq "GET") {
            Send-Json -Response $response -Data (Get-TelemetryLogs)
        } elseif ($path -eq "/api/clear-telemetry" -and $method -eq "POST") {
            Send-Json -Response $response -Data (Clear-TelemetryLogs)
        } elseif ($path -eq "/api/get-restore-points" -and $method -eq "GET") {
            Send-Json -Response $response -Data (Get-SystemRestorePoints)
        } elseif ($path -eq "/api/restore-system" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $sequenceNumber = $data.sequenceNumber
            Send-Json -Response $response -Data (Restore-System -SequenceNumber $sequenceNumber)
        } elseif ($path -eq "/api/backup-registry" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $keyPath = $data.keyPath
            $backupPath = $data.backupPath
            Send-Json -Response $response -Data (Backup-RegistryKey -KeyPath $keyPath -BackupPath $backupPath)
        } elseif ($path -eq "/api/restore-registry" -and $method -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $data = $body | ConvertFrom-Json
            $backupPath = $data.backupPath
            Send-Json -Response $response -Data (Restore-RegistryKey -BackupPath $backupPath)
        }
        # --- Servir arquivos estáticos --- #
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
} catch {
    Write-Host "[$(Get-Date)] [ERRO CRITICO] $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
        $listener.Close()
    }
    Write-Host "[$(Get-Date)] [INFO] Motor a vapor desligado." -ForegroundColor DarkRed
}
