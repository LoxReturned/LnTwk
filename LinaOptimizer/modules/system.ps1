# system.ps1 - System Tweaks Module - ULTIMATE V8.0 (MASTERPIECE)
# Encoding: UTF-8 with BOM

# --- Funções Auxiliares (assumindo que são carregadas globalmente ou definidas aqui) ---
# function Test-RegistryValue { ... }
# function Set-RegistryValue { ... }
# function Remove-RegistryValue { ... }
# function Test-ServiceStatus { ... }
# function Set-ServiceStatus { ... }
# function Add-TelemetryEntry { ... } # Para logs

# --- Tweaks de Sistema --- #
function Get-SystemTweaks {
    $tweaks = @(
        @{
            id = "DisableTelemetry";
            title = "Desativar Telemetria";
            titleEn = "Disable Telemetry";
            description = "Desativa a coleta de dados de telemetria do Windows, aumentando a privacidade.";
            category = "Privacidade";
            tags = @("privacy", "telemetry", "data_collection");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("privacy", "system_resources");
            whatItDoes = "Impede o envio de dados de uso e diagnóstico para a Microsoft.";
            whatItDoesEn = "Prevents sending usage and diagnostic data to Microsoft.";
            enables = "Maior privacidade e menor consumo de recursos em segundo plano.";
            enablesEn = "Increased privacy and lower background resource consumption.";
            disables = "Recursos de diagnóstico e melhoria de produtos da Microsoft.";
            disablesEn = "Microsoft product diagnostic and improvement features.";
            detect = { (Test-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ExpectedValue 0) -and (Test-ServiceStatus -Name "DiagTrack" -Status "Disabled") };
            apply = {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -PropertyType "DWord"
                Set-ServiceStatus -Name "DiagTrack" -Status "Disabled"
                Set-ServiceStatus -Name "dmwappushsvc" -Status "Disabled"
            };
            revert = {
                Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"
                Set-ServiceStatus -Name "DiagTrack" -Status "Automatic"
                Set-ServiceStatus -Name "dmwappushsvc" -Status "Automatic"
            };
        },
        @{
            id = "DisableErrorReporting";
            title = "Desativar Relatório de Erros";
            titleEn = "Disable Error Reporting";
            description = "Impede o Windows de enviar relatórios de erros para a Microsoft.";
            category = "Privacidade";
            tags = @("privacy", "error_reporting", "system_resources");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $false;
            impact = @("privacy", "system_resources");
            whatItDoes = "Evita que o sistema envie automaticamente informações sobre falhas de software.";
            whatItDoesEn = "Prevents the system from automatically sending software crash information.";
            enables = "Maior privacidade e menor uso de rede/disco em segundo plano.";
            enablesEn = "Increased privacy and lower background network/disk usage.";
            disables = "Envio automático de dados de falha para a Microsoft para análise.";
            disablesEn = "Automatic sending of crash data to Microsoft for analysis.";
            detect = { (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -ExpectedValue 1) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled"
            };
        },
        @{
            id = "DisableAdvertisingID";
            title = "Desativar ID de Publicidade";
            titleEn = "Disable Advertising ID";
            description = "Desativa o ID de publicidade usado por aplicativos para anúncios personalizados.";
            category = "Privacidade";
            tags = @("privacy", "advertising");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("privacy");
            whatItDoes = "Impede que aplicativos usem um identificador único para rastrear seus interesses para publicidade.";
            whatItDoesEn = "Prevents apps from using a unique identifier to track your interests for advertising.";
            enables = "Maior privacidade e menos anúncios personalizados.";
            enablesEn = "Increased privacy and fewer personalized ads.";
            disables = "Publicidade personalizada baseada em seus hábitos de uso.";
            disablesEn = "Personalized advertising based on your usage habits.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled"
            };
        },
        @{
            id = "DisableGameDVR";
            title = "Desativar Game DVR";
            titleEn = "Disable Game DVR";
            description = "Desativa a gravação de jogos em segundo plano do Xbox Game Bar, liberando recursos.";
            category = "Jogos";
            tags = @("gaming", "xbox", "system_resources");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("fps", "system_resources");
            whatItDoes = "Impede que o Windows grave automaticamente sua jogabilidade, economizando CPU e RAM.";
            whatItDoesEn = "Prevents Windows from automatically recording your gameplay, saving CPU and RAM.";
            enables = "Melhor desempenho em jogos e menor consumo de recursos.";
            enablesEn = "Better gaming performance and lower resource consumption.";
            disables = "Funcionalidade de gravação de tela e captura de clipes do Xbox Game Bar.";
            disablesEn = "Screen recording and clip capture functionality of Xbox Game Bar.";
            detect = { (Test-RegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ExpectedValue 0) -and (Test-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled"
                Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR"
            };
        },
        @{
            id = "DisableXboxServices";
            title = "Desativar Serviços Xbox";
            titleEn = "Disable Xbox Services";
            description = "Desativa serviços relacionados ao Xbox que podem consumir recursos em segundo plano.";
            category = "Jogos";
            tags = @("gaming", "xbox", "system_resources");
            risk = "medium";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("system_resources");
            whatItDoes = "Interrompe serviços como autenticação Xbox e rede, que podem rodar mesmo sem jogos Xbox.";
            whatItDoesEn = "Stops services like Xbox authentication and networking, which can run even without Xbox games.";
            enables = "Liberação de RAM e CPU, melhorando o desempenho geral do sistema.";
            enablesEn = "Freeing up RAM and CPU, improving overall system performance.";
            disables = "Funcionalidades de jogos Xbox, como multiplayer e autenticação.";
            disablesEn = "Xbox gaming functionalities, such as multiplayer and authentication.";
            detect = { (Test-ServiceStatus -Name "XblAuthManager" -Status "Disabled") -and (Test-ServiceStatus -Name "XboxGipSvc" -Status "Disabled") };
            apply = {
                Set-ServiceStatus -Name "XblAuthManager" -Status "Disabled"
                Set-ServiceStatus -Name "XboxGipSvc" -Status "Disabled"
                Set-ServiceStatus -Name "XboxNetApiSvc" -Status "Disabled"
                Set-ServiceStatus -Name "GamingServices" -Status "Disabled"
            };
            revert = {
                Set-ServiceStatus -Name "XblAuthManager" -Status "Manual"
                Set-ServiceStatus -Name "XboxGipSvc" -Status "Manual"
                Set-ServiceStatus -Name "XboxNetApiSvc" -Status "Manual"
                Set-ServiceStatus -Name "GamingServices" -Status "Manual"
            };
        },
        @{
            id = "DisableSuperfetch";
            title = "Desativar Superfetch/SysMain";
            titleEn = "Disable Superfetch/SysMain";
            description = "Pode melhorar o desempenho em PCs com SSDs, pois o Superfetch é mais útil para HDDs.";
            category = "Sistema";
            tags = @("ssd", "hdd", "system_resources");
            risk = "medium";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("disk_io", "ram_usage");
            whatItDoes = "Impede que o Windows pré-carregue aplicativos frequentemente usados na RAM.";
            whatItDoesEn = "Prevents Windows from preloading frequently used applications into RAM.";
            enables = "Redução do uso de RAM e atividade de disco em SSDs.";
            enablesEn = "Reduced RAM usage and disk activity on SSDs.";
            disables = "Carregamento mais rápido de aplicativos frequentemente usados em HDDs.";
            disablesEn = "Faster loading of frequently used applications on HDDs.";
            detect = { (Test-ServiceStatus -Name "SysMain" -Status "Disabled") };
            apply = { Set-ServiceStatus -Name "SysMain" -Status "Disabled" };
            revert = { Set-ServiceStatus -Name "SysMain" -Status "Automatic" };
        },
        @{
            id = "DisablePrefetch";
            title = "Desativar Prefetch";
            titleEn = "Disable Prefetch";
            description = "Desativa o Prefetch, que pré-carrega dados de aplicativos. Pode ser útil em SSDs.";
            category = "Sistema";
            tags = @("ssd", "hdd", "system_resources");
            risk = "medium";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("disk_io");
            whatItDoes = "Impede que o Windows crie arquivos de cache para acelerar o carregamento de programas.";
            whatItDoesEn = "Prevents Windows from creating cache files to speed up program loading.";
            enables = "Redução da atividade de disco em SSDs.";
            enablesEn = "Reduced disk activity on SSDs.";
            disables = "Carregamento ligeiramente mais rápido de programas em HDDs.";
            disablesEn = "Slightly faster program loading on HDDs.";
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableHibernation";
            title = "Desativar Hibernação";
            titleEn = "Disable Hibernation";
            description = "Desativa a hibernação e remove o arquivo hiberfil.sys, liberando espaço em disco.";
            category = "Sistema";
            tags = @("disk_space", "power_management");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("disk_space");
            whatItDoes = "Remove a opção de hibernar e apaga o arquivo hiberfil.sys, que pode ser grande.";
            whatItDoesEn = "Removes the hibernation option and deletes the hiberfil.sys file, which can be large.";
            enables = "Liberação de espaço em disco e inicialização mais rápida (se você não usa hibernação).";
            enablesEn = "Freeing up disk space and faster startup (if you don't use hibernation).";
            disables = "Capacidade de hibernar o sistema, salvando o estado da sessão.";
            disablesEn = "Ability to hibernate the system, saving the session state.";
            detect = { (powercfg /hibernate off | Select-String "not available" -ErrorAction SilentlyContinue) }; # Check if hibernation is off
            apply = { powercfg /hibernate off };
            revert = { powercfg /hibernate on };
        },
        @{
            id = "DisableOneDrive";
            title = "Desativar OneDrive";
            titleEn = "Disable OneDrive";
            description = "Desativa e desinstala o OneDrive, se não for utilizado, liberando recursos.";
            category = "Debloat";
            tags = @("cloud", "system_resources", "privacy");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("ram_usage", "cpu_usage", "disk_space");
            whatItDoes = "Remove o OneDrive do sistema, liberando recursos e espaço em disco.";
            whatItDoesEn = "Removes OneDrive from the system, freeing up resources and disk space.";
            enables = "Liberação de RAM, CPU e espaço em disco.";
            enablesEn = "Freeing up RAM, CPU, and disk space.";
            disables = "Sincronização de arquivos na nuvem com o OneDrive.";
            disablesEn = "Cloud file synchronization with OneDrive.";
            detect = { (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue) -eq $null };
            apply = {
                taskkill /f /im OneDrive.exe -ErrorAction SilentlyContinue
                & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall -ErrorAction SilentlyContinue
                & "$env:SystemRoot\System32\OneDriveSetup.exe" /uninstall -ErrorAction SilentlyContinue
            };
            revert = {
                & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ErrorAction SilentlyContinue
                & "$env:SystemRoot\System32\OneDriveSetup.exe" -ErrorAction SilentlyContinue
            };
        },
        @{
            id = "DisablePrintSpooler";
            title = "Desativar Spooler de Impressão";
            titleEn = "Disable Print Spooler";
            description = "Desativa o serviço de impressão se você não usa impressoras, economizando RAM.";
            category = "Sistema";
            tags = @("system_resources", "services");
            risk = "medium";
            needsAdmin = $true;
            needsRestart = $false;
            impact = @("ram_usage");
            whatItDoes = "Interrompe o serviço que gerencia trabalhos de impressão.";
            whatItDoesEn = "Stops the service that manages print jobs.";
            enables = "Liberação de RAM e CPU se você não imprime.";
            enablesEn = "Freeing up RAM and CPU if you don't print.";
            disables = "Capacidade de imprimir documentos.";
            disablesEn = "Ability to print documents.";
            detect = { (Test-ServiceStatus -Name "Spooler" -Status "Disabled") };
            apply = { Set-ServiceStatus -Name "Spooler" -Status "Disabled" };
            revert = { Set-ServiceStatus -Name "Spooler" -Status "Automatic" };
        },
        @{
            id = "DisableWindowsDefender";
            title = "Desativar Windows Defender";
            titleEn = "Disable Windows Defender";
            description = "Desativa o Windows Defender. Use apenas se tiver outro antivírus.";
            category = "Segurança";
            tags = @("security", "antivirus", "system_resources");
            risk = "high";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("system_resources", "security");
            whatItDoes = "Desativa o antivírus padrão do Windows.";
            whatItDoesEn = "Disables the default Windows antivirus.";
            enables = "Liberação de RAM e CPU, mas com risco de segurança se não tiver outro antivírus.";
            enablesEn = "Freeing up RAM and CPU, but with security risk if you don't have another antivirus.";
            disables = "Proteção em tempo real contra malwares do Windows Defender.";
            disablesEn = "Real-time malware protection from Windows Defender.";
            detect = { (Test-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ExpectedValue 1) -and (Test-ServiceStatus -Name "WinDefend" -Status "Disabled") };
            apply = {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType "DWord"
                Set-ServiceStatus -Name "WinDefend" -Status "Disabled"
            };
            revert = {
                Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware"
                Set-ServiceStatus -Name "WinDefend" -Status "Automatic"
            };
        },
        @{
            id = "DisableWindowsUpdate";
            title = "Desativar Windows Update";
            titleEn = "Disable Windows Update";
            description = "Desativa as atualizações automáticas do Windows. Cuidado ao usar.";
            category = "Sistema";
            tags = @("updates", "system_resources");
            risk = "high";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("system_resources", "security");
            whatItDoes = "Impede que o Windows baixe e instale atualizações automaticamente.";
            whatItDoesEn = "Prevents Windows from automatically downloading and installing updates.";
            enables = "Controle total sobre quando as atualizações são instaladas e menor uso de rede/disco.";
            enablesEn = "Full control over when updates are installed and lower network/disk usage.";
            disables = "Atualizações de segurança e recursos importantes do Windows.";
            disablesEn = "Security updates and important Windows features.";
            detect = { (Test-ServiceStatus -Name "wuauserv" -Status "Disabled") };
            apply = { Set-ServiceStatus -Name "wuauserv" -Status "Disabled" };
            revert = { Set-ServiceStatus -Name "wuauserv" -Status "Automatic" };
        },
        @{
            id = "DisableSearchIndexing";
            title = "Desativar Indexação de Busca";
            titleEn = "Disable Search Indexing";
            description = "Desativa o serviço de indexação de arquivos, liberando recursos de disco e CPU.";
            category = "Sistema";
            tags = @("disk_io", "cpu_usage");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $false;
            impact = @("disk_io", "cpu_usage");
            whatItDoes = "Impede que o Windows crie um índice de seus arquivos para buscas rápidas.";
            whatItDoesEn = "Prevents Windows from creating an index of your files for quick searches.";
            enables = "Redução da atividade de disco e CPU em segundo plano.";
            enablesEn = "Reduced background disk activity and CPU usage.";
            disables = "Buscas de arquivos mais rápidas no Explorador de Arquivos.";
            disablesEn = "Faster file searches in File Explorer.";
            detect = { (Test-ServiceStatus -Name "WSearch" -Status "Disabled") };
            apply = { Set-ServiceStatus -Name "WSearch" -Status "Disabled" };
            revert = { Set-ServiceStatus -Name "WSearch" -Status "Automatic" };
        },
        @{
            id = "OptimizeBoot";
            title = "Otimizar Inicialização";
            titleEn = "Optimize Boot";
            description = "Acelera a inicialização do Windows desativando atrasos e otimizando o boot.";
            category = "Sistema";
            tags = @("boot", "startup");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("boot_time");
            whatItDoes = "Ajusta parâmetros para um carregamento mais rápido do sistema operacional.";
            whatItDoesEn = "Adjusts parameters for faster operating system loading.";
            enables = "Inicialização mais rápida do Windows.";
            enablesEn = "Faster Windows startup.";
            disables = "Alguns processos de pré-carregamento que podem ser desnecessários.";
            disablesEn = "Some preloading processes that may be unnecessary.";
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -ExpectedValue 0) -and (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableBootTrace" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 0 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableBootTrace" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 3 -PropertyType "DWord"
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableBootTrace" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableUAC";
            title = "Desativar UAC (Controle de Conta de Usuário)";
            titleEn = "Disable UAC (User Account Control)";
            description = "Desativa as notificações do UAC. Reduz a segurança, use com cautela.";
            category = "Segurança";
            tags = @("security", "notifications");
            risk = "high";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("security");
            whatItDoes = "Impede que o Windows peça confirmação para ações que exigem privilégios de administrador.";
            whatItDoesEn = "Prevents Windows from asking for confirmation for actions requiring administrator privileges.";
            enables = "Menos interrupções ao instalar programas ou fazer alterações no sistema.";
            enablesEn = "Fewer interruptions when installing programs or making system changes.";
            disables = "Camada de segurança contra programas maliciosos que tentam fazer alterações sem sua permissão.";
            disablesEn = "Security layer against malicious programs trying to make changes without your permission.";
            detect = { (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableWindowsTips";
            title = "Desativar Dicas do Windows";
            titleEn = "Disable Windows Tips";
            description = "Desativa as dicas e sugestões do Windows, que podem consumir recursos.";
            category = "Privacidade";
            tags = @("privacy", "notifications", "system_resources");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("system_resources");
            whatItDoes = "Impede que o Windows exiba notificações com sugestões de uso.";
            whatItDoesEn = "Prevents Windows from displaying notifications with usage suggestions.";
            enables = "Menos interrupções e menor consumo de recursos em segundo plano.";
            enablesEn = "Fewer interruptions and lower background resource consumption.";
            disables = "Dicas e sugestões personalizadas do Windows.";
            disablesEn = "Personalized Windows tips and suggestions.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableActionCenter";
            title = "Desativar Central de Ações";
            titleEn = "Disable Action Center";
            description = "Desativa as notificações da Central de Ações.";
            category = "Interface";
            tags = @("notifications", "interface");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("interface");
            whatItDoes = "Remove o ícone e as notificações da Central de Ações na barra de tarefas.";
            whatItDoesEn = "Removes the Action Center icon and notifications from the taskbar.";
            enables = "Interface mais limpa e menos distrações.";
            enablesEn = "Cleaner interface and fewer distractions.";
            disables = "Acesso rápido a notificações e configurações rápidas do sistema.";
            disablesEn = "Quick access to notifications and quick system settings.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ENABLED" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ENABLED" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ENABLED" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableBackgroundApps";
            title = "Desativar Apps em Segundo Plano";
            titleEn = "Disable Background Apps";
            description = "Impede que aplicativos da Microsoft Store rodem em segundo plano.";
            category = "Privacidade";
            tags = @("privacy", "system_resources", "apps");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("ram_usage", "cpu_usage");
            whatItDoes = "Impede que aplicativos da loja consumam recursos quando não estão em uso ativo.";
            whatItDoesEn = "Prevents store apps from consuming resources when not in active use.";
            enables = "Liberação de RAM e CPU, melhorando o desempenho geral.";
            enablesEn = "Freeing up RAM and CPU, improving overall performance.";
            disables = "Notificações e atualizações em tempo real de aplicativos da Microsoft Store.";
            disablesEn = "Real-time notifications and updates from Microsoft Store apps.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ExpectedValue 1) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableVisualEffects";
            title = "Desativar Efeitos Visuais";
            titleEn = "Disable Visual Effects";
            description = "Desativa animações e efeitos visuais para um desempenho mais rápido.";
            category = "Interface";
            tags = @("interface", "performance");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("gpu_usage", "cpu_usage");
            whatItDoes = "Remove animações de janelas, sombras e outros efeitos gráficos.";
            whatItDoesEn = "Removes window animations, shadows, and other graphical effects.";
            enables = "Interface mais responsiva e menor consumo de GPU/CPU.";
            enablesEn = "More responsive interface and lower GPU/CPU consumption.";
            disables = "Efeitos visuais modernos do Windows.";
            disablesEn = "Modern Windows visual effects.";
            detect = { (Test-RegistryValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -ExpectedValue 0) -and (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ExpectedValue 2) };
            apply = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -PropertyType "String"
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 1 -PropertyType "String"
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableMouseAcceleration";
            title = "Desativar Aceleração do Mouse";
            titleEn = "Disable Mouse Acceleration";
            description = "Remove a aceleração do mouse para maior precisão em jogos.";
            category = "Input";
            tags = @("gaming", "mouse", "latency");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("gaming_precision");
            whatItDoes = "Faz com que o movimento do cursor seja diretamente proporcional ao movimento físico do mouse.";
            whatItDoesEn = "Makes cursor movement directly proportional to physical mouse movement.";
            enables = "Maior precisão e consistência no movimento do mouse, ideal para jogos FPS.";
            enablesEn = "Greater precision and consistency in mouse movement, ideal for FPS games.";
            disables = "Aceleração do mouse, que pode ajudar em tarefas de produtividade.";
            disablesEn = "Mouse acceleration, which can help in productivity tasks.";
            detect = { (Test-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -ExpectedValue 10) -and (Test-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -ExpectedValue "00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00") };
            apply = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value 10 -PropertyType "String"
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value "00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00" -PropertyType "Binary"
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Value "00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00" -PropertyType "Binary"
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value 0 -PropertyType "String"
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value 0 -PropertyType "String"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value 10 -PropertyType "String"
                Remove-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve"
                Remove-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve"
                Remove-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1"
                Remove-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2"
            };
        },
        @{
            id = "DisableStickyKeys";
            title = "Desativar Teclas de Aderência";
            titleEn = "Disable Sticky Keys";
            description = "Desativa as Teclas de Aderência para evitar interrupções.";
            category = "Input";
            tags = @("accessibility", "gaming");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("gaming_experience");
            whatItDoes = "Impede que o Windows ative funções de acessibilidade ao pressionar Shift várias vezes.";
            whatItDoesEn = "Prevents Windows from activating accessibility features when pressing Shift multiple times.";
            enables = "Experiência de jogo ininterrupta.";
            enablesEn = "Uninterrupted gaming experience.";
            disables = "Funcionalidade de acessibilidade para usuários com dificuldades motoras.";
            disablesEn = "Accessibility functionality for users with motor difficulties.";
            detect = { (Test-RegistryValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -ExpectedValue 506) };
            apply = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value 506 -PropertyType "String"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value 510 -PropertyType "String"
            };
        },
        @{
            id = "DisableFilterKeys";
            title = "Desativar Teclas de Filtragem";
            titleEn = "Disable Filter Keys";
            description = "Desativa as Teclas de Filtragem para evitar atrasos na digitação.";
            category = "Input";
            tags = @("accessibility", "gaming");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("gaming_experience");
            whatItDoes = "Impede que o Windows ignore pressionamentos de tecla repetidos rapidamente.";
            whatItDoesEn = "Prevents Windows from ignoring rapidly repeated key presses.";
            enables = "Digitação e resposta de teclado mais precisas.";
            enablesEn = "More precise typing and keyboard response.";
            disables = "Funcionalidade de acessibilidade para usuários com tremores ou dificuldades de digitação.";
            disablesEn = "Accessibility functionality for users with tremors or typing difficulties.";
            detect = { (Test-RegistryValue -Path "HKCU:\Control Panel\Accessibility\FilterKeys" -Name "Flags" -ExpectedValue 506) };
            apply = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\FilterKeys" -Name "Flags" -Value 506 -PropertyType "String"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\FilterKeys" -Name "Flags" -Value 510 -PropertyType "String"
            };
        },
        @{
            id = "DisableToggleKeys";
            title = "Desativar Teclas de Alternância";
            titleEn = "Disable Toggle Keys";
            description = "Desativa as Teclas de Alternância para evitar sons de Caps Lock, Num Lock, etc.";
            category = "Input";
            tags = @("accessibility", "notifications");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("user_experience");
            whatItDoes = "Impede que o Windows emita sons ao pressionar Caps Lock, Num Lock ou Scroll Lock.";
            whatItDoesEn = "Prevents Windows from emitting sounds when pressing Caps Lock, Num Lock, or Scroll Lock.";
            enables = "Experiência de uso mais silenciosa e menos distrações.";
            enablesEn = "Quieter user experience and fewer distractions.";
            disables = "Feedback sonoro para o estado das teclas de alternância.";
            disablesEn = "Auditory feedback for the state of toggle keys.";
            detect = { (Test-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -ExpectedValue 506) };
            apply = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value 506 -PropertyType "String"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value 510 -PropertyType "String"
            };
        },
        @{
            id = "DisableMouseTrails";
            title = "Desativar Rastros do Mouse";
            titleEn = "Disable Mouse Trails";
            description = "Remove os rastros do mouse para uma experiência mais limpa.";
            category = "Interface";
            tags = @("interface", "visual_effects");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("visual_clarity");
            whatItDoes = "Impede que o cursor do mouse deixe um rastro visual ao se mover.";
            whatItDoesEn = "Prevents the mouse cursor from leaving a visual trail when moving.";
            enables = "Movimento do cursor mais limpo e preciso.";
            enablesEn = "Cleaner and more precise cursor movement.";
            disables = "Efeito visual de rastro do mouse.";
            disablesEn = "Visual effect of mouse trails.";
            detect = { (Test-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Value 0 -PropertyType "String"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Value 1 -PropertyType "String"
            };
        },
        @{
            id = "DisableExplorerRecent";
            title = "Desativar Itens Recentes no Explorer";
            titleEn = "Disable Recent Items in Explorer";
            description = "Impede o Explorer de mostrar arquivos e pastas recentes.";
            category = "Privacidade";
            tags = @("privacy", "explorer");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("privacy");
            whatItDoes = "Remove a lista de arquivos e pastas acessados recentemente do Explorador de Arquivos.";
            whatItDoesEn = "Removes the list of recently accessed files and folders from File Explorer.";
            enables = "Maior privacidade e interface mais limpa no Explorador de Arquivos.";
            enablesEn = "Increased privacy and cleaner interface in File Explorer.";
            disables = "Acesso rápido a documentos e pastas recentes.";
            disablesEn = "Quick access to recent documents and folders.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecentDocs" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecentDocs" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecentDocs" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "ShowFileExtensions";
            title = "Mostrar Extensões de Arquivo";
            titleEn = "Show File Extensions";
            description = "Exibe as extensões de arquivo no Windows Explorer.";
            category = "Interface";
            tags = @("explorer", "interface");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("user_experience");
            whatItDoes = "Faz com que o Windows mostre .txt, .exe, .jpg, etc., nos nomes dos arquivos.";
            whatItDoesEn = "Makes Windows show .txt, .exe, .jpg, etc., in file names.";
            enables = "Maior clareza sobre o tipo de arquivo e segurança (evita arquivos .exe disfarçados).";
            enablesEn = "Greater clarity about file type and security (avoids disguised .exe files).";
            disables = "Ocultamento de extensões de arquivo conhecidas.";
            disablesEn = "Hiding of known file extensions.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "ShowHiddenFiles";
            title = "Mostrar Arquivos Ocultos";
            titleEn = "Show Hidden Files";
            description = "Exibe arquivos e pastas ocultos no Windows Explorer.";
            category = "Interface";
            tags = @("explorer", "interface");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("user_experience");
            whatItDoes = "Torna visíveis arquivos e pastas que normalmente são ocultados pelo sistema.";
            whatItDoesEn = "Makes files and folders normally hidden by the system visible.";
            enables = "Acesso total a todos os arquivos do sistema para manutenção avançada.";
            enablesEn = "Full access to all system files for advanced maintenance.";
            disables = "Ocultamento de arquivos e pastas do sistema para evitar modificações acidentais.";
            disablesEn = "Hiding of system files and folders to prevent accidental modifications.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -ExpectedValue 1) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableAutoPlay";
            title = "Desativar AutoPlay";
            titleEn = "Disable AutoPlay";
            description = "Impede a execução automática de mídias removíveis.";
            category = "Sistema";
            tags = @("security", "usability");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("security");
            whatItDoes = "Evita que CDs, DVDs ou pendrives iniciem automaticamente ao serem conectados.";
            whatItDoesEn = "Prevents CDs, DVDs, or USB drives from starting automatically when connected.";
            enables = "Maior segurança contra malwares em mídias removíveis.";
            enablesEn = "Increased security against malware on removable media.";
            disables = "Conveniência de execução automática de mídias.";
            disablesEn = "Convenience of automatic media execution.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -ExpectedValue 255) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 145 -PropertyType "DWord"
            };
        },
        @{
            id = "DisablePowerThrottling";
            title = "Desativar Power Throttling";
            titleEn = "Disable Power Throttling";
            description = "Impede que o Windows reduza o desempenho de aplicativos em segundo plano para economizar energia.";
            category = "Sistema";
            tags = @("performance", "power_management");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("cpu_performance");
            whatItDoes = "Garante que aplicativos em segundo plano recebam recursos totais da CPU.";
            whatItDoesEn = "Ensures background applications receive full CPU resources.";
            enables = "Melhor desempenho para aplicativos em segundo plano, como downloads ou renderização.";
            enablesEn = "Better performance for background applications, such as downloads or rendering.";
            disables = "Economia de energia para prolongar a vida útil da bateria em notebooks.";
            disablesEn = "Power saving to extend battery life on laptops.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundActivityModerator" -Name "EnablePowerThrottling" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundActivityModerator" -Name "EnablePowerThrottling" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundActivityModerator" -Name "EnablePowerThrottling" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableFastStartup";
            title = "Desativar Inicialização Rápida";
            titleEn = "Disable Fast Startup";
            description = "Desativa a Inicialização Rápida do Windows, que pode causar problemas com dual-boot e atualizações.";
            category = "Sistema";
            tags = @("boot", "power_management");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $true;
            impact = @("boot_time");
            whatItDoes = "Impede que o Windows salve o estado do kernel em um arquivo para inicializar mais rápido.";
            whatItDoesEn = "Prevents Windows from saving the kernel state to a file for faster startup.";
            enables = "Evita problemas com dual-boot, acesso a partições Linux e atualizações do Windows.";
            enablesEn = "Avoids issues with dual-boot, access to Linux partitions, and Windows updates.";
            disables = "Inicialização ligeiramente mais rápida do Windows.";
            disablesEn = "Slightly faster Windows startup.";
            detect = { (Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableGameBar";
            title = "Desativar Xbox Game Bar";
            titleEn = "Disable Xbox Game Bar";
            description = "Desativa completamente a Xbox Game Bar, liberando recursos do sistema.";
            category = "Jogos";
            tags = @("gaming", "xbox", "system_resources");
            risk = "low";
            needsAdmin = $true;
            needsRestart = $false;
            impact = @("fps", "system_resources");
            whatItDoes = "Remove a sobreposição e funcionalidades da Xbox Game Bar.";
            whatItDoesEn = "Removes the Xbox Game Bar overlay and functionalities.";
            enables = "Melhor desempenho em jogos e menor consumo de recursos.";
            enablesEn = "Better gaming performance and lower resource consumption.";
            disables = "Funcionalidades da Xbox Game Bar, como chat, widgets e gravação.";
            disablesEn = "Xbox Game Bar functionalities, such as chat, widgets, and recording.";
            detect = { (Get-AppxPackage Microsoft.XboxGamingOverlay -ErrorAction SilentlyContinue) -eq $null };
            apply = {
                Get-AppxPackage Microsoft.XboxGamingOverlay | Remove-AppxPackage -ErrorAction SilentlyContinue
            };
            revert = {
                Add-AppxPackage -Register "$($env:SystemRoot)\SystemApps\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe\AppxManifest.xml" -DisableDevelopmentMode -ErrorAction SilentlyContinue
            };
        },
        @{
            id = "DisableOneDriveSync";
            title = "Desativar Sincronização OneDrive";
            titleEn = "Disable OneDrive Sync";
            description = "Desativa a sincronização automática de arquivos do OneDrive.";
            category = "Privacidade";
            tags = @("cloud", "privacy", "system_resources");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("network_usage", "disk_io");
            whatItDoes = "Impede que o OneDrive sincronize arquivos em segundo plano.";
            whatItDoesEn = "Prevents OneDrive from syncing files in the background.";
            enables = "Menor uso de rede e disco, e maior privacidade.";
            enablesEn = "Lower network and disk usage, and increased privacy.";
            disables = "Sincronização automática de arquivos com a nuvem do OneDrive.";
            disablesEn = "Automatic file synchronization with OneDrive cloud.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Name "DisableFileSync" -ExpectedValue 1) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Name "DisableFileSync" -Value 1 -PropertyType "DWord"
            };
            revert = {
                Remove-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Name "DisableFileSync"
            };
        },
        @{
            id = "DisableGameMode";
            title = "Desativar Modo de Jogo";
            titleEn = "Disable Game Mode";
            description = "Desativa o Modo de Jogo do Windows, que pode causar problemas de desempenho em alguns sistemas.";
            category = "Jogos";
            tags = @("gaming", "performance");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("fps");
            whatItDoes = "Impede que o Windows otimize automaticamente o sistema para jogos.";
            whatItDoesEn = "Prevents Windows from automatically optimizing the system for games.";
            enables = "Pode resolver problemas de stuttering ou queda de FPS em alguns jogos.";
            enablesEn = "Can resolve stuttering or FPS drops in some games.";
            disables = "Otimizações automáticas do Windows para jogos.";
            disablesEn = "Automatic Windows optimizations for games.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowGameMode" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowGameMode" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowGameMode" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableBackgroundRecording";
            title = "Desativar Gravação em Segundo Plano";
            titleEn = "Disable Background Recording";
            description = "Desativa a gravação de clipes de jogos em segundo plano, liberando recursos.";
            category = "Jogos";
            tags = @("gaming", "system_resources");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("fps", "system_resources");
            whatItDoes = "Impede que o Windows grave automaticamente os últimos momentos da sua jogabilidade.";
            whatItDoesEn = "Prevents Windows from automatically recording the last moments of your gameplay.";
            enables = "Melhor desempenho em jogos e menor consumo de recursos.";
            enablesEn = "Better gaming performance and lower resource consumption.";
            disables = "Funcionalidade de gravação instantânea de clipes de jogos.";
            disablesEn = "Instant game clip recording functionality.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "DVREnabled" -ExpectedValue 0) };
            apply = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "DVREnabled" -Value 0 -PropertyType "DWord"
            };
            revert = {
                Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "DVREnabled" -Value 1 -PropertyType "DWord"
            };
        },
        @{
            id = "DisableFocusAssist";
            title = "Desativar Assistente de Foco";
            titleEn = "Disable Focus Assist";
            description = "Desativa o Assistente de Foco para evitar interrupções durante jogos ou trabalho.";
            category = "Sistema";
            tags = @("notifications", "usability");
            risk = "low";
            needsAdmin = $false;
            needsRestart = $false;
            impact = @("user_experience");
            whatItDoes = "Impede que o Windows oculte notificações para evitar distrações.";
            whatItDoesEn = "Prevents Windows from hiding notifications to avoid distractions.";
            enables = "Recebimento de todas as notificações em tempo real.";
            enablesEn = "Receiving all notifications in real time.";
            disables = "Funcionalidade de gerenciamento de notificações para evitar distrações.";
            disablesEn = "Notification management functionality to avoid distractions.";
            detect = { (Test-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ENABLED" -ExpectedValue 1) }; # Placeholder, needs actual detect for Focus Assist
            apply = {
                # Implementar lógica para desativar Focus Assist
            };
            revert = {
                # Implementar lógica para reverter Focus Assist
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
    $tweak = (Get-SystemTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1
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

    $tweak = (Get-SystemTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

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

    $tweak = (Get-SystemTweaks | Where-Object { $_.id -eq $TweakId }) | Select-Object -First 1

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
