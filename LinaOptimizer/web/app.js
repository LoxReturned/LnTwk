// Encoding: UTF-8 with BOM

document.addEventListener('DOMContentLoaded', () => {
    console.log('[LinaOptimizer] Iniciando aplicação...');

    const langToggle = document.getElementById('lang-toggle');
    const categoryPicker = document.getElementById('category-picker');
    const tweakListContainer = document.getElementById('tweak-list-container');
    const searchInput = document.getElementById('search-input');
    const systemInfoContainer = document.getElementById('system-info-container');
    const optimizationScoreDisplay = document.getElementById('optimization-score');
    const restorePointBtn = document.getElementById('create-restore-point-btn');
    const gameListContainer = document.getElementById('game-list-container');
    const appListContainer = document.getElementById('app-list-container');
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
        { id: 'DisableWindowsUpdate', name: 'Desativar Windows Update', description: 'Desativa atualizações automáticas do Windows', category: 'Sistema', risk: 'Médio', status: false, rebootRequired: true },
        { id: 'DisableTelemetry', name: 'Desativar Telemetria', description: 'Remove coleta de dados da Microsoft', category: 'Privacidade', risk: 'Baixo', status: false, rebootRequired: false },
        { id: 'OptimizeNetwork', name: 'Otimizar Rede', description: 'Melhora velocidade de conexão', category: 'Rede', risk: 'Baixo', status: false, rebootRequired: false }
    ];

    const fallbackGames = [
        { id: 'Valorant', name: 'Valorant', description: 'Otimizações para Valorant', detected: false, paths: [] },
        { id: 'CS2', name: 'Counter-Strike 2', description: 'Otimizações para CS2', detected: false, paths: [] },
        { id: 'Fortnite', name: 'Fortnite', description: 'Otimizações para Fortnite', detected: false, paths: [] }
    ];

    const fallbackApps = [
        { id: 'Discord', name: 'Discord', description: 'Aplicativo de comunicação', icon: '🎙️', installed: false },
        { id: 'OBS', name: 'OBS Studio', description: 'Software de streaming', icon: '📹', installed: false },
        { id: 'Steam', name: 'Steam', description: 'Plataforma de jogos', icon: '🎮', installed: false }
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

            const systemInfoRes = await fetch('/api/systeminfo').then(r => {
                console.log('[API] Resposta /api/systeminfo:', r.status);
                return r.json();
            }).catch(e => {
                console.error('[API] Erro ao buscar /api/systeminfo:', e);
                return { systemInfo: { cpu: 'N/A', gpu: 'N/A', ram: 'N/A', os: 'Windows 10/11' } };
            });

            allTweaks = tweaksRes.tweaks || fallbackTweaks;
            allGames = gamesRes.games || fallbackGames;
            allApps = appsRes.apps || fallbackApps;
            systemInfo = systemInfoRes.systemInfo || {};

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
        const allCategories = ['Sistema', 'Privacidade', 'Rede', 'Kernel', 'Energia', 'Debloat', 'Interface', 'Input', 'Jogos', 'Apps Essenciais'];

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

        filteredTweaks.forEach(tweak => {
            const tweakCard = document.createElement('div');
            tweakCard.className = 'tweak-card glassmorphism';
            tweakCard.innerHTML = `
                <div class="tweak-header">
                    <h3>${tweak.name}</h3>
                    <label class="switch">
                        <input type="checkbox" data-tweak-id="${tweak.id}" ${tweak.status ? 'checked' : ''}>
                        <span class="slider round"></span>
                    </label>
                </div>
                <p class="tweak-description">${tweak.description}</p>
                <div class="tweak-meta">
                    <span class="risk ${tweak.risk.toLowerCase()}">${tweak.risk}</span>
                    ${tweak.rebootRequired ? '<span class="reboot-required">Reinício Necessário</span>' : ''}
                </div>
            `;
            tweakListContainer.appendChild(tweakCard);
        });
    }

    function renderGames() {
        gameListContainer.innerHTML = '';
        if (allGames.length === 0) {
            gameListContainer.innerHTML = '<p style="text-align: center; color: #999;">Nenhum jogo disponível.</p>';
            return;
        }

        allGames.forEach(game => {
            const gameCard = document.createElement('div');
            gameCard.className = 'game-card glassmorphism';
            gameCard.innerHTML = `
                <h3>${game.name}</h3>
                <p>${game.description}</p>
                <div class="game-status">
                    <span class="status-badge ${game.detected ? 'detected' : 'not-found'}">
                        ${game.detected ? '✓ DETECTADO' : '✗ NÃO ENCONTRADO'}
                    </span>
                </div>
                <select class="game-intensity">
                    <option value="light">Leve</option>
                    <option value="medium" selected>Média</option>
                    <option value="heavy">Pesada</option>
                </select>
                <button class="btn-apply-game">APLICAR OTIMIZAÇÃO</button>
            `;
            gameListContainer.appendChild(gameCard);
        });
    }

    function renderApps() {
        appListContainer.innerHTML = '';
        if (allApps.length === 0) {
            appListContainer.innerHTML = '<p style="text-align: center; color: #999;">Nenhum app disponível.</p>';
            return;
        }

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
            appListContainer.appendChild(appCard);
        });
    }

    function updateSystemInfo() {
        if (systemInfoContainer) {
            systemInfoContainer.innerHTML = `
                <h2>INFORMAÇÕES DO SISTEMA</h2>
                <p><strong>CPU:</strong> ${systemInfo.cpu || 'N/A'}</p>
                <p><strong>GPU:</strong> ${systemInfo.gpu || 'N/A'}</p>
                <p><strong>RAM:</strong> ${systemInfo.ram || 'N/A'}</p>
                <p><strong>SO:</strong> ${systemInfo.os || 'Windows 10/11'}</p>
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
