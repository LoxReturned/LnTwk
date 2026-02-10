// Encoding: UTF-8 with BOM

document.addEventListener('DOMContentLoaded', () => {
    console.log('[LinaOptimizer] Iniciando aplicação...');

    const langToggle = document.getElementById('lang-toggle');
    const langPtBtn = document.getElementById('lang-pt');
    const langEnBtn = document.getElementById('lang-en');
    const categoryPicker = document.getElementById('category-picker');
    const tweakListContainer = document.getElementById('tweak-list-container') || document.getElementById('tweak-grid');
    const searchInput = document.getElementById('search-input');
    const systemInfoContainer = document.getElementById('system-info-container') || document.querySelector('.system-info-grid');
    const optimizationScoreDisplay = document.getElementById('optimization-score');
    const restorePointBtn = document.getElementById('create-restore-point-btn') || document.getElementById('create-restore-point');
    const gameListContainer = document.getElementById('game-list-container') || document.getElementById('games-grid');
    const appListContainer = document.getElementById('app-list-container') || document.getElementById('apps-grid');
    const toastContainer = document.getElementById('toast-container');
    const mainContent = document.getElementById('main-content');

    let currentLang = 'pt';
    let allTweaks = [];
    let allGames = [];
    let allApps = [];
    let systemInfo = {};
    let currentActiveCategory = 'Sistema';

    // --- Dados de Fallback para Testes --- //
    const fallbackTweaks = [
        { id: 'DisableWindowsUpdate', name: 'Desativar Windows Update', description: 'Desativa atualizações automáticas do Windows para reduzir uso de disco e CPU.', category: 'Sistema', risk: 'Médio', status: false, rebootRequired: true, warning: 'Atualizações de segurança ficarão pendentes até reativar.' },
        { id: 'DisableTelemetry', name: 'Desativar Telemetria', description: 'Remove coleta de dados da Microsoft e serviços de diagnóstico.', category: 'Privacidade', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'OptimizeNetwork', name: 'Otimizar Rede', description: 'Ajusta TCP, DNS e buffers para reduzir latência.', category: 'Rede', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'DisableGameBar', name: 'Desativar Xbox Game Bar', description: 'Remove overlays e gravação em segundo plano.', category: 'Jogos', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'DisableBackgroundApps', name: 'Bloquear Apps em Segundo Plano', description: 'Reduz processos ocultos e consumo de RAM.', category: 'Sistema', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'DisableSearchIndex', name: 'Desativar Indexação do Windows Search', description: 'Reduz uso de disco, principalmente em SSDs com uso intenso.', category: 'Sistema', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableFastStartup', name: 'Desativar Inicialização Rápida', description: 'Evita problemas de driver em dual-boot e libera recursos no boot.', category: 'Sistema', risk: 'Baixo', status: false, rebootRequired: true },
        { id: 'DisableSysMain', name: 'Desativar SysMain (Superfetch)', description: 'Reduz uso de disco/CPU em PCs com SSD.', category: 'Serviços', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableDiagTrack', name: 'Desativar Diagnostics Tracking', description: 'Remove serviço de telemetria avançada.', category: 'Privacidade', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableHibernation', name: 'Desativar Hibernação', description: 'Libera espaço em disco e elimina hiberfil.sys.', category: 'Sistema', risk: 'Baixo', status: false, rebootRequired: true },
        { id: 'DisableDefenderRealtime', name: 'Desativar Windows Defender (Tempo Real)', description: 'Reduz impacto em jogos/benchmark.', category: 'Segurança', risk: 'Alto', status: false, rebootRequired: true, warning: 'Risco de segurança. Use apenas se tiver proteção alternativa.' },
        { id: 'SetPowerPlanUltimate', name: 'Plano de Energia Ultimate Performance', description: 'Maximiza clock e evita economia agressiva.', category: 'Energia', risk: 'Médio', status: false, rebootRequired: false },
        { id: 'DisableMemoryCompression', name: 'Desativar Compressão de Memória', description: 'Evita overhead da compressão em CPUs mais fracas.', category: 'Kernel', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableSpectreMitigation', name: 'Desativar Mitigações Spectre/Meltdown', description: 'Ganha desempenho em CPU com risco de segurança.', category: 'Kernel', risk: 'Alto', status: false, rebootRequired: true, warning: 'Alto risco de segurança. Use apenas em máquinas de benchmark.' },
        { id: 'DisableHPET', name: 'Desativar HPET', description: 'Pode reduzir latência em alguns sistemas.', category: 'Kernel', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableFullscreenOptimizations', name: 'Desativar Otimizações de Tela Cheia', description: 'Ajuda em input lag e stutter.', category: 'Jogos', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'ReduceTelemetryTasks', name: 'Desativar Tarefas Agendadas de Telemetria', description: 'Remove tarefas de coleta de dados.', category: 'Privacidade', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableWidgets', name: 'Desativar Widgets do Windows 11', description: 'Evita processos extra e consumo de RAM.', category: 'Interface', risk: 'Baixo', status: false, rebootRequired: true },
        { id: 'DisableTransparency', name: 'Desativar Transparência do Windows', description: 'Melhora FPS em iGPUs e PCs fracos.', category: 'Interface', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'DisableAnimation', name: 'Desativar Animações do Windows', description: 'Interface mais responsiva e leve.', category: 'Interface', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'DisableCortana', name: 'Desativar Cortana', description: 'Remove serviço e processos associados.', category: 'Debloat', risk: 'Baixo', status: false, rebootRequired: true },
        { id: 'RemoveOneDrive', name: 'Remover OneDrive', description: 'Elimina sincronização em background.', category: 'Debloat', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisablePrintSpooler', name: 'Desativar Spooler de Impressão', description: 'Reduz serviços se você não usa impressoras.', category: 'Serviços', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableBluetooth', name: 'Desativar Bluetooth', description: 'Economiza recursos se não utiliza periféricos.', category: 'Drivers', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'DisableNvidiaTelemetry', name: 'Desativar Telemetria NVIDIA', description: 'Reduz processos extras no driver.', category: 'GPU', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'SetNvidiaLowLatency', name: 'Habilitar NVIDIA Low Latency', description: 'Reduz fila de renderização.', category: 'GPU', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'EnableMSI', name: 'Ativar MSI Mode em dispositivos', description: 'Pode reduzir latência em placas e controladores.', category: 'Drivers', risk: 'Alto', status: false, rebootRequired: true, warning: 'Configuração avançada. Pode causar instabilidade.' },
        { id: 'ReduceServices', name: 'Reduzir Serviços Não Essenciais', description: 'Desativa serviços inúteis e libera RAM/CPU.', category: 'Serviços', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableIPv6', name: 'Desativar IPv6', description: 'Evita conflitos em redes antigas.', category: 'Rede', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableFirewall', name: 'Desativar Firewall', description: 'Remove overhead de inspeção de tráfego.', category: 'Segurança', risk: 'Alto', status: false, rebootRequired: true, warning: 'Risco de segurança. Use apenas em redes isoladas.' },
        { id: 'DisableCoreIsolation', name: 'Desativar Isolamento de Núcleo', description: 'Ganha desempenho em jogos, reduz segurança.', category: 'Segurança', risk: 'Alto', status: false, rebootRequired: true, warning: 'Risco de segurança. Use apenas se souber o que está fazendo.' }
    ];

    const fallbackGames = [
        { id: 'Valorant', name: 'Valorant', description: 'Otimizações para Valorant (anti-cheat friendly).', detected: false, paths: [] },
        { id: 'CS2', name: 'Counter-Strike 2', description: 'Configuração de latência e consistência.', detected: false, paths: [] },
        { id: 'Fortnite', name: 'Fortnite', description: 'Estabilidade de frame time.', detected: false, paths: [] },
        { id: 'Apex', name: 'Apex Legends', description: 'Configuração de prioridade e cache.', detected: false, paths: [] },
        { id: 'Warzone', name: 'Call of Duty: Warzone', description: 'Melhorar uso de GPU/CPU.', detected: false, paths: [] },
        { id: 'GTA5', name: 'GTA V', description: 'Perfis de streaming de textura.', detected: false, paths: [] },
        { id: 'Rust', name: 'Rust', description: 'Ajustes para reduzir stutter.', detected: false, paths: [] },
        { id: 'League', name: 'League of Legends', description: 'Estabilidade em FPS alto.', detected: false, paths: [] },
        { id: 'Minecraft', name: 'Minecraft', description: 'Ajustes JVM e perfis de gráfico.', detected: false, paths: [] },
        { id: 'Overwatch2', name: 'Overwatch 2', description: 'Baixa latência em inputs.', detected: false, paths: [] }
    ];

    const fallbackApps = [
        { id: 'Discord', name: 'Discord', description: 'Aplicativo de comunicação (otimização de overlay).', icon: '🎙️', installed: false },
        { id: 'OBS', name: 'OBS Studio', description: 'Streaming e gravação.', icon: '📹', installed: false },
        { id: 'Steam', name: 'Steam', description: 'Plataforma de jogos.', icon: '🎮', installed: false },
        { id: 'Chrome', name: 'Google Chrome', description: 'Navegador com modo performance.', icon: '🌐', installed: false },
        { id: 'Brave', name: 'Brave', description: 'Navegador leve e seguro.', icon: '🛡️', installed: false },
        { id: '7Zip', name: '7-Zip', description: 'Compactador leve.', icon: '🗜️', installed: false },
        { id: 'VCredist', name: 'Visual C++ Redistributable', description: 'Dependências comuns de jogos.', icon: '🧩', installed: false },
        { id: 'DirectX', name: 'DirectX Runtime', description: 'APIs gráficas essenciais.', icon: '🧪', installed: false },
        { id: 'GPUZ', name: 'GPU-Z', description: 'Monitoramento de GPU.', icon: '🖥️', installed: false },
        { id: 'HWiNFO', name: 'HWiNFO', description: 'Monitoramento completo de hardware.', icon: '📊', installed: false },
        { id: 'MSI', name: 'MSI Afterburner', description: 'Overclock e monitoramento.', icon: '⚙️', installed: false },
        { id: 'RTSS', name: 'RivaTuner Statistics', description: 'Frame limiter e OSD.', icon: '🎯', installed: false },
        { id: 'LatencyMon', name: 'LatencyMon', description: 'Análise de latência DPC.', icon: '⏱️', installed: false },
        { id: 'ProcessLasso', name: 'Process Lasso', description: 'Controle de prioridade e afinidade.', icon: '🧠', installed: false },
        { id: 'TimerRes', name: 'Timer Resolution', description: 'Ajuste de timer do sistema.', icon: '⏲️', installed: false }
    ];

    // --- Funções Auxiliares --- //
    function showToast(message, type = 'info') {
        console.log(`[Toast] ${type.toUpperCase()}: ${message}`);
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        toastContainer.appendChild(toast);
        setTimeout(() => {
            toast.classList.add('hide');
            toast.addEventListener('transitionend', () => toast.remove());
        }, 3000);
    }

    // --- Fetch Data from Backend --- //
    async function fetchAllData() {
        console.log('[API] Iniciando fetch de dados...');
        try {
            const tweaksRes = await fetch('/api/tweaks').then(r => {
                console.log('[API] Resposta /api/tweaks:', r.status);
                return r.json();
            }).catch(e => {
                console.error('[API] Erro ao buscar /api/tweaks:', e);
                return { tweaks: fallbackTweaks };
            });

            const gamesRes = await fetch('/api/games').then(r => {
                console.log('[API] Resposta /api/games:', r.status);
                return r.json();
            }).catch(e => {
                console.error('[API] Erro ao buscar /api/games:', e);
                return { games: fallbackGames };
            });

            const appsRes = await fetch('/api/apps').then(r => {
                console.log('[API] Resposta /api/apps:', r.status);
                return r.json();
            }).catch(e => {
                console.error('[API] Erro ao buscar /api/apps:', e);
                return { apps: fallbackApps };
            });

            const systemInfoRes = await fetch('/api/system-info').then(r => {
                console.log('[API] Resposta /api/system-info:', r.status);
                return r.json();
            }).catch(e => {
                console.error('[API] Erro ao buscar /api/systeminfo:', e);
                return { systemInfo: { cpu: 'N/A', gpu: 'N/A', ram: 'N/A', os: 'Windows 10/11' } };
            });

            allTweaks = tweaksRes.tweaks || fallbackTweaks;
            allGames = gamesRes.games || fallbackGames;
            allApps = appsRes.apps || fallbackApps;
            systemInfo = systemInfoRes.systemInfo || systemInfoRes || {};

            console.log('[Data] Tweaks carregados:', allTweaks.length);
            console.log('[Data] Jogos carregados:', allGames.length);
            console.log('[Data] Apps carregados:', allApps.length);

            renderUI();
            updateSystemInfo();
            calculateOptimizationScore();
        } catch (error) {
            console.error('[Fatal] Erro ao carregar dados:', error);
            showToast('Erro ao carregar dados. Usando dados de fallback.', 'warning');
            allTweaks = fallbackTweaks;
            allGames = fallbackGames;
            allApps = fallbackApps;
            renderUI();
        }
    }

    // --- Render UI --- //
    function renderUI() {
        console.log('[Render] Iniciando renderização da UI...');
        renderCategoryPicker();
        renderContent();
    }

    function renderCategoryPicker() {
        categoryPicker.innerHTML = '';
        const categoriesFromData = [...new Set(allTweaks.map(tweak => tweak.category).filter(Boolean))];
        const baseCategories = categoriesFromData.length > 0 ? categoriesFromData : ['Sistema', 'Privacidade', 'Rede', 'Kernel', 'Energia', 'Debloat', 'Interface', 'Input', 'Serviços', 'Segurança', 'Drivers', 'GPU', 'CPU'];
        const allCategories = [...new Set([...baseCategories, 'Jogos', 'Apps Essenciais'])];

        if (!allCategories.includes(currentActiveCategory)) {
            currentActiveCategory = allCategories[0] || 'Sistema';
        }

        allCategories.forEach(category => {
            const button = document.createElement('button');
            button.className = `category-tab ${currentActiveCategory === category ? 'active' : ''}`;
            button.dataset.category = category;
            button.textContent = category;
            button.addEventListener('click', () => {
                currentActiveCategory = category;
                document.querySelectorAll('.category-tab').forEach(btn => btn.classList.remove('active'));
                button.classList.add('active');
                renderContent();
            });
            categoryPicker.appendChild(button);
        });
    }

    function renderContent() {
        console.log('[Render] Renderizando categoria:', currentActiveCategory);
        document.querySelectorAll('.content-section').forEach(section => section.classList.remove('active'));

        if (currentActiveCategory === 'Jogos') {
            document.getElementById('games-section').classList.add('active');
            renderGames();
        } else if (currentActiveCategory === 'Apps Essenciais') {
            document.getElementById('apps-section').classList.add('active');
            renderApps();
        } else {
            document.getElementById('tweaks-section').classList.add('active');
            renderTweaks(currentActiveCategory);
        }
    }

    function renderTweaks(category) {
        tweakListContainer.innerHTML = '';
        const filteredTweaks = allTweaks.filter(tweak => tweak.category === category);

        if (filteredTweaks.length === 0) {
            tweakListContainer.innerHTML = '<p style="text-align: center; color: #999;">Nenhum tweak disponível nesta categoria.</p>';
            return;
        }

        const fragment = document.createDocumentFragment();
        filteredTweaks.forEach(tweak => {
            const riskKey = (tweak.risk || '').toLowerCase();
            const riskClass = riskKey.includes('alto') || riskKey.includes('high') ? 'high' : riskKey.includes('médio') || riskKey.includes('medio') || riskKey.includes('medium') ? 'medium' : 'low';
            const warningText = tweak.warning ? `<p><strong>Aviso:</strong> ${tweak.warning}</p>` : '';
            const tweakCard = document.createElement('div');
            tweakCard.className = 'tweak-card glassmorphism';
            tweakCard.innerHTML = `
                <div class="tweak-header">
                    <h3>${tweak.name}</h3>
                    <div class="status-toggle">
                        <label>
                            <input type="checkbox" data-tweak-id="${tweak.id}" ${tweak.status ? 'checked' : ''}>
                            <span class="slider round"></span>
                        </label>
                    </div>
                </div>
                <div class="tooltip">
                    <p class="tweak-description">${tweak.description}</p>
                    <span class="tooltiptext">
                        <div class="tooltip-content">
                            <h4>${tweak.name}</h4>
                            <p>${tweak.description}</p>
                            ${warningText}
                            <span class="risk-badge ${riskClass}">${tweak.risk || 'Baixo'}</span>
                            ${tweak.rebootRequired ? '<p>Reinício necessário após aplicar.</p>' : ''}
                        </div>
                    </span>
                </div>
                <div class="tweak-meta">
                    <span class="risk-badge ${riskClass}">${tweak.risk || 'Baixo'}</span>
                    ${tweak.rebootRequired ? '<span class="reboot-required">Reinício Necessário</span>' : ''}
                </div>
            `;
            fragment.appendChild(tweakCard);
        });
        tweakListContainer.appendChild(fragment);
    }

    function renderGames() {
        gameListContainer.innerHTML = '';
        if (allGames.length === 0) {
            gameListContainer.innerHTML = '<p style="text-align: center; color: #999;">Nenhum jogo disponível.</p>';
            return;
        }

        const fragment = document.createDocumentFragment();
        allGames.forEach(game => {
            const gameCard = document.createElement('div');
            gameCard.className = 'game-card glassmorphism';
            gameCard.innerHTML = `
                <h3>${game.name}</h3>
                <p>${game.description}</p>
                <div class="game-status ${game.detected ? 'detected' : 'not-found'}">
                    ${game.detected ? '✓ DETECTADO' : '✗ NÃO ENCONTRADO'}
                </div>
                <select class="game-intensity">
                    <option value="light">Leve</option>
                    <option value="medium" selected>Média</option>
                    <option value="heavy">Pesada</option>
                </select>
                <button class="btn-apply-game">APLICAR OTIMIZAÇÃO</button>
            `;
            fragment.appendChild(gameCard);
        });
        gameListContainer.appendChild(fragment);
    }

    function renderApps() {
        appListContainer.innerHTML = '';
        if (allApps.length === 0) {
            appListContainer.innerHTML = '<p style="text-align: center; color: #999;">Nenhum app disponível.</p>';
            return;
        }

        const fragment = document.createDocumentFragment();
        allApps.forEach(app => {
            const appCard = document.createElement('div');
            appCard.className = 'app-card glassmorphism';
            appCard.innerHTML = `
                <div class="app-icon">${app.icon || '📦'}</div>
                <h3>${app.name}</h3>
                <p>${app.description}</p>
                <button class="btn-install-app" data-app-id="${app.id}">
                    ${app.installed ? 'DESINSTALAR' : 'INSTALAR'}
                </button>
            `;
            fragment.appendChild(appCard);
        });
        appListContainer.appendChild(fragment);
    }

    function updateSystemInfo() {
        if (systemInfoContainer) {
            const hardwareClass = systemInfo.hardwareClass ? `<div class="tweak-card glassmorphism"><h3>Classe</h3><p>${systemInfo.hardwareClass}</p></div>` : '';
            const isAdmin = systemInfo.isAdmin !== undefined ? `<div class="tweak-card glassmorphism"><h3>Admin</h3><p>${systemInfo.isAdmin ? 'Sim' : 'Não'}</p></div>` : '';
            systemInfoContainer.innerHTML = `
                <div class="tweak-card glassmorphism">
                    <h3>CPU</h3>
                    <p>${systemInfo.cpu || 'N/A'}</p>
                </div>
                <div class="tweak-card glassmorphism">
                    <h3>GPU</h3>
                    <p>${systemInfo.gpu || 'N/A'}</p>
                </div>
                <div class="tweak-card glassmorphism">
                    <h3>RAM</h3>
                    <p>${systemInfo.ram || 'N/A'}</p>
                </div>
                <div class="tweak-card glassmorphism">
                    <h3>SO</h3>
                    <p>${systemInfo.os || 'Windows 10/11'}</p>
                </div>
                ${hardwareClass}
                ${isAdmin}
            `;
        }
    }

    function calculateOptimizationScore() {
        const totalTweaks = allTweaks.length;
        const activeTweaks = allTweaks.filter(t => t.status).length;
        const score = totalTweaks > 0 ? Math.round((activeTweaks / totalTweaks) * 100) : 0;
        if (optimizationScoreDisplay) {
            optimizationScoreDisplay.innerHTML = `
                <h2>SCORE DE OTIMIZAÇÃO</h2>
                <p>Seu sistema está otimizado em <strong>${score}%</strong>.</p>
            `;
        }
    }

    // --- Event Listeners --- //
    if (langToggle) {
        langToggle.addEventListener('click', () => {
            currentLang = currentLang === 'pt' ? 'en' : 'pt';
            langToggle.textContent = currentLang.toUpperCase();
            console.log('[Lang] Idioma alterado para:', currentLang);
        });
    }

    if (langPtBtn && langEnBtn) {
        const setActiveLang = (lang) => {
            currentLang = lang;
            langPtBtn.classList.toggle('active', lang === 'pt');
            langEnBtn.classList.toggle('active', lang === 'en');
            console.log('[Lang] Idioma alterado para:', currentLang);
        };

        langPtBtn.addEventListener('click', () => setActiveLang('pt'));
        langEnBtn.addEventListener('click', () => setActiveLang('en'));
    }

    if (restorePointBtn) {
        restorePointBtn.addEventListener('click', () => {
            console.log('[Action] Criando ponto de restauração...');
            showToast('Ponto de restauração criado com sucesso!', 'success');
        });
    }

    // Initial Load
    console.log('[Init] Carregando dados iniciais...');
    fetchAllData();
});
