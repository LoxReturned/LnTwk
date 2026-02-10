// Encoding: UTF-8 with BOM

document.addEventListener('DOMContentLoaded', () => {
    const dom = {
        categoryPicker: document.getElementById('category-picker'),
        tweakListContainer: document.getElementById('tweak-list-container') || document.getElementById('tweak-grid'),
        searchInput: document.getElementById('search-input'),
        systemInfoContainer: document.getElementById('system-info-container') || document.querySelector('.system-info-grid'),
        restorePointBtn: document.getElementById('create-restore-point-btn') || document.getElementById('create-restore-point'),
        activateBtn: document.getElementById('activate-optimizations'),
        gameListContainer: document.getElementById('game-list-container') || document.getElementById('games-grid'),
        appListContainer: document.getElementById('app-list-container') || document.getElementById('apps-grid'),
        toastContainer: document.getElementById('toast-container'),
        modeSelect: document.getElementById('mode-select'),
        dryRunToggle: document.getElementById('dry-run-toggle'),
        rollbackAllBtn: document.getElementById('rollback-all-btn'),
        snapshotBtn: document.getElementById('snapshot-btn'),
        logsOutput: document.getElementById('logs-output'),
        exportLogsBtn: document.getElementById('export-logs-btn'),
        langPtBtn: document.getElementById('lang-pt'),
        langEnBtn: document.getElementById('lang-en')
    };

    const state = {
        mode: 'safe',
        dryRun: false,
        lang: 'pt',
        activeCategory: 'Sistema',
        tweaks: [],
        games: [],
        apps: [],
        systemInfo: {},
        snapshots: [],
        logs: [],
        appliedTweaks: new Map()
    };

    const fallbackTweaks = [
        { id: 'DisableWindowsUpdate', name: 'Desativar Windows Update', description: 'Reduz atividade em disco e CPU.', category: 'Sistema', risk: 'Médio', rebootRequired: true, dependencies: [], tags: ['serviços', 'windows'] },
        { id: 'DisableTelemetry', name: 'Desativar Telemetria', description: 'Reduz coleta de dados e processos de diagnóstico.', category: 'Privacidade', risk: 'Baixo', rebootRequired: false, dependencies: [], tags: ['privacidade'] },
        { id: 'OptimizeNetwork', name: 'Otimizar Rede', description: 'Ajusta stack TCP para latência menor.', category: 'Rede', risk: 'Baixo', rebootRequired: false, dependencies: [], tags: ['latência', 'tcp'] },
        { id: 'SetPowerPlanUltimate', name: 'Ultimate Performance', description: 'Plano de energia focado em desempenho.', category: 'Energia', risk: 'Médio', rebootRequired: false, dependencies: [], tags: ['cpu', 'energia'] },
        { id: 'DisableCoreIsolation', name: 'Desativar Core Isolation', description: 'Pode reduzir overhead de segurança.', category: 'Segurança', risk: 'Alto', rebootRequired: true, dependencies: ['SetPowerPlanUltimate'], warning: 'Aumenta risco de segurança do sistema.', tags: ['segurança'] },
        { id: 'DisableHPET', name: 'Desativar HPET', description: 'Pode melhorar latência em alguns sistemas.', category: 'Kernel', risk: 'Médio', rebootRequired: true, dependencies: [], tags: ['timer', 'kernel'] },
        { id: 'EnableMSIMode', name: 'Ativar MSI Mode', description: 'Ajuste avançado de interrupções em dispositivos.', category: 'Drivers', risk: 'Alto', rebootRequired: true, dependencies: [], warning: 'Configuração avançada. Pode causar instabilidade.', tags: ['irq', 'drivers'] },
        { id: 'DisableGameBar', name: 'Desativar Xbox Game Bar', description: 'Reduz overlays e captura em segundo plano.', category: 'Jogos', risk: 'Baixo', rebootRequired: false, dependencies: [], tags: ['gaming'] },
        { id: 'DisableFullscreenOptimizations', name: 'Desativar Fullscreen Optimizations', description: 'Melhora consistência de frametime em jogos.', category: 'Jogos', risk: 'Baixo', rebootRequired: false, dependencies: [], tags: ['frametime'] },
        { id: 'DisableSearchIndex', name: 'Desativar Indexação', description: 'Menor uso de disco em carga alta.', category: 'Sistema', risk: 'Médio', rebootRequired: true, dependencies: [], tags: ['disco'] },
        { id: 'DisableMemoryCompression', name: 'Desativar Compressão de Memória', description: 'Pode melhorar responsividade em CPU limitada.', category: 'Kernel', risk: 'Médio', rebootRequired: true, dependencies: [], tags: ['ram'] },
        { id: 'DisableSpectreMitigation', name: 'Desativar Mitigações Spectre/Meltdown', description: 'Ganho de desempenho em cenários específicos.', category: 'Kernel', risk: 'Alto', rebootRequired: true, dependencies: ['DisableCoreIsolation'], warning: 'Use apenas em ambiente controlado.', tags: ['segurança', 'cpu'] }
    ];

    const fallbackGames = [
        { id: 'CS2', name: 'Counter-Strike 2', description: 'Preset para baixa latência.', detected: false },
        { id: 'Valorant', name: 'Valorant', description: 'Preset de estabilidade e input.', detected: false },
        { id: 'Fortnite', name: 'Fortnite', description: 'Preset de frametime.', detected: false },
        { id: 'Warzone', name: 'Warzone', description: 'Preset CPU/GPU balance.', detected: false }
    ];

    const fallbackApps = [
        { id: 'Discord', name: 'Discord', description: 'Comunicação', icon: '🎙️', installed: false },
        { id: 'OBS', name: 'OBS Studio', description: 'Streaming', icon: '📹', installed: false },
        { id: 'MSIAfterburner', name: 'MSI Afterburner', description: 'Monitoramento e OC', icon: '⚙️', installed: false },
        { id: 'RTSS', name: 'RivaTuner', description: 'Limiter e OSD', icon: '🎯', installed: false },
        { id: 'HWiNFO', name: 'HWiNFO', description: 'Telemetria de hardware', icon: '📊', installed: false }
    ];

    function showToast(message, type = 'info') {
        if (!dom.toastContainer) return;
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        dom.toastContainer.appendChild(toast);
        setTimeout(() => toast.remove(), 3200);
    }

    function logEvent(level, action, details = {}) {
        const entry = {
            ts: new Date().toISOString(),
            level,
            action,
            mode: state.mode,
            dryRun: state.dryRun,
            details
        };
        state.logs.push(entry);
        if (state.logs.length > 200) state.logs.shift();
        renderLogs();
    }

    function renderLogs() {
        if (!dom.logsOutput) return;
        dom.logsOutput.textContent = state.logs
            .slice(-20)
            .map(log => `[${log.ts}] [${log.level.toUpperCase()}] ${log.action} ${JSON.stringify(log.details)}`)
            .join('\n');
    }

    function normalizeRisk(risk) {
        const key = String(risk || 'Baixo').toLowerCase();
        if (key.includes('alto') || key.includes('high')) return { label: 'Alto', className: 'high' };
        if (key.includes('médio') || key.includes('medio') || key.includes('medium')) return { label: 'Médio', className: 'medium' };
        return { label: 'Baixo', className: 'low' };
    }

    async function fetchJson(url, fallback) {
        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            logEvent('warn', 'fetch_fallback', { url, error: error.message });
            return fallback;
        }
    }

    async function fetchAllData() {
        const [tweaksRes, gamesRes, appsRes, systemInfoRes] = await Promise.all([
            fetchJson('/api/tweaks', { tweaks: fallbackTweaks }),
            fetchJson('/api/games', { games: fallbackGames }),
            fetchJson('/api/apps', { apps: fallbackApps }),
            fetchJson('/api/system-info', { systemInfo: { cpu: 'N/A', gpu: 'N/A', ram: 'N/A', os: 'Windows 10/11' } })
        ]);

        state.tweaks = (tweaksRes.tweaks || fallbackTweaks).map(t => ({ ...t, status: Boolean(t.status), dependencies: t.dependencies || [] }));
        state.games = gamesRes.games || fallbackGames;
        state.apps = appsRes.apps || fallbackApps;
        state.systemInfo = systemInfoRes.systemInfo || systemInfoRes || {};

        state.tweaks.forEach(t => {
            if (t.status) state.appliedTweaks.set(t.id, true);
        });

        renderAll();
        logEvent('info', 'initial_data_loaded', { tweaks: state.tweaks.length, games: state.games.length, apps: state.apps.length });
    }

    function getCategories() {
        const categories = [...new Set(state.tweaks.map(t => t.category).filter(Boolean))];
        return [...categories, 'Jogos', 'Apps Essenciais'];
    }

    function renderCategories() {
        if (!dom.categoryPicker) return;
        const categories = getCategories();
        if (!categories.includes(state.activeCategory)) state.activeCategory = categories[0] || 'Sistema';
        dom.categoryPicker.innerHTML = '';

        const fragment = document.createDocumentFragment();
        categories.forEach(category => {
            const btn = document.createElement('button');
            btn.className = state.activeCategory === category ? 'active category-tab' : 'category-tab';
            btn.textContent = category;
            btn.addEventListener('click', () => {
                state.activeCategory = category;
                renderContent();
            });
            fragment.appendChild(btn);
        });
        dom.categoryPicker.appendChild(fragment);
    }

    function applyFilter(tweaks) {
        const query = (dom.searchInput?.value || '').trim().toLowerCase();
        if (!query) return tweaks;
        return tweaks.filter(tweak =>
            tweak.name.toLowerCase().includes(query) ||
            tweak.description.toLowerCase().includes(query) ||
            (tweak.tags || []).some(tag => String(tag).toLowerCase().includes(query))
        );
    }

    function checkDependencies(tweak) {
        const missing = (tweak.dependencies || []).filter(dep => !state.appliedTweaks.get(dep));
        return { ok: missing.length === 0, missing };
    }

    function toggleTweak(tweakId, desiredStatus) {
        const tweak = state.tweaks.find(t => t.id === tweakId);
        if (!tweak) return;

        const risk = normalizeRisk(tweak.risk);
        if (desiredStatus) {
            const dep = checkDependencies(tweak);
            if (!dep.ok) {
                showToast(`Dependências pendentes: ${dep.missing.join(', ')}`, 'error');
                logEvent('warn', 'dependency_block', { tweakId, missing: dep.missing });
                renderContent();
                return;
            }

            if (risk.className === 'high' && state.mode === 'safe') {
                showToast('Modo Seguro bloqueia tweaks de alto risco.', 'warning');
                logEvent('warn', 'risk_blocked_by_mode', { tweakId, mode: state.mode });
                renderContent();
                return;
            }

            if (risk.className === 'high' && !window.confirm(`Tweak crítico: ${tweak.name}. Deseja aplicar mesmo assim?`)) {
                renderContent();
                return;
            }
        }

        if (state.dryRun) {
            showToast(`[Dry-run] ${desiredStatus ? 'Aplicaria' : 'Reverteria'} ${tweak.name}`, 'info');
            logEvent('info', 'dry_run_toggle', { tweakId, desiredStatus });
            renderContent();
            return;
        }

        tweak.status = desiredStatus;
        if (desiredStatus) state.appliedTweaks.set(tweak.id, true);
        else state.appliedTweaks.delete(tweak.id);
        logEvent('info', desiredStatus ? 'tweak_applied' : 'tweak_reverted', { tweakId });
        showToast(`${tweak.name}: ${desiredStatus ? 'ativado' : 'revertido'}.`, desiredStatus ? 'success' : 'info');
        renderContent();
    }

    function renderTweaks() {
        if (!dom.tweakListContainer) return;
        const section = document.getElementById('tweaks-section');
        const gamesSection = document.getElementById('games-section');
        const appsSection = document.getElementById('apps-section');
        section?.classList.add('active');
        gamesSection?.classList.remove('active');
        appsSection?.classList.remove('active');

        const filtered = applyFilter(state.tweaks.filter(t => t.category === state.activeCategory));
        dom.tweakListContainer.innerHTML = '';
        if (filtered.length === 0) {
            dom.tweakListContainer.innerHTML = '<p style="color:#999;text-align:center;">Nenhum tweak encontrado para esse filtro.</p>';
            return;
        }

        const fragment = document.createDocumentFragment();
        filtered.forEach(tweak => {
            const dep = checkDependencies(tweak);
            const risk = normalizeRisk(tweak.risk);
            const card = document.createElement('div');
            card.className = 'tweak-card glassmorphism';
            card.innerHTML = `
                <div class="tweak-header">
                    <h3>${tweak.name}</h3>
                    <div class="status-toggle"><label>
                        <input type="checkbox" data-tweak-id="${tweak.id}" ${tweak.status ? 'checked' : ''}>
                        <span class="slider round"></span>
                    </label></div>
                </div>
                <p class="tweak-description">${tweak.description}</p>
                ${tweak.warning ? `<p><strong>Aviso:</strong> ${tweak.warning}</p>` : ''}
                ${!dep.ok ? `<p><strong>Dependências:</strong> ${dep.missing.join(', ')}</p>` : ''}
                <div class="tweak-meta">
                    <span class="risk-badge ${risk.className}">${risk.label}</span>
                    ${tweak.rebootRequired ? '<span class="reboot-required">Reinício necessário</span>' : ''}
                </div>
            `;

            const input = card.querySelector('input[data-tweak-id]');
            input?.addEventListener('change', e => toggleTweak(tweak.id, e.target.checked));
            fragment.appendChild(card);
        });
        dom.tweakListContainer.appendChild(fragment);
    }

    function renderGames() {
        const section = document.getElementById('tweaks-section');
        const gamesSection = document.getElementById('games-section');
        const appsSection = document.getElementById('apps-section');
        section?.classList.remove('active');
        gamesSection?.classList.add('active');
        appsSection?.classList.remove('active');

        if (!dom.gameListContainer) return;
        dom.gameListContainer.innerHTML = '';
        const fragment = document.createDocumentFragment();
        state.games.forEach(game => {
            const card = document.createElement('div');
            card.className = 'game-card glassmorphism';
            card.innerHTML = `
                <h3>${game.name}</h3>
                <p>${game.description || 'Sem descrição.'}</p>
                <div class="game-status ${game.detected ? 'detected' : 'not-found'}">${game.detected ? '✓ Detectado' : '✗ Não encontrado'}</div>
                <button class="btn-apply-game">Aplicar perfil ${state.mode.toUpperCase()}</button>
            `;
            card.querySelector('.btn-apply-game')?.addEventListener('click', () => {
                logEvent('info', 'game_profile_apply', { gameId: game.id, mode: state.mode, dryRun: state.dryRun });
                showToast(`${state.dryRun ? '[Dry-run] ' : ''}Perfil aplicado para ${game.name}.`, 'success');
            });
            fragment.appendChild(card);
        });
        dom.gameListContainer.appendChild(fragment);
    }

    function renderApps() {
        const section = document.getElementById('tweaks-section');
        const gamesSection = document.getElementById('games-section');
        const appsSection = document.getElementById('apps-section');
        section?.classList.remove('active');
        gamesSection?.classList.remove('active');
        appsSection?.classList.add('active');

        if (!dom.appListContainer) return;
        dom.appListContainer.innerHTML = '';
        const fragment = document.createDocumentFragment();
        state.apps.forEach(app => {
            const card = document.createElement('div');
            card.className = 'app-card glassmorphism';
            card.innerHTML = `
                <div class="app-icon">${app.icon || '📦'}</div>
                <h3>${app.name}</h3>
                <p>${app.description || ''}</p>
                <button class="btn-install-app" data-app-id="${app.id}">${app.installed ? 'Desinstalar' : 'Instalar'}</button>
            `;
            card.querySelector('.btn-install-app')?.addEventListener('click', () => {
                logEvent('info', 'app_toggle', { appId: app.id, action: app.installed ? 'uninstall' : 'install' });
                showToast(`${state.dryRun ? '[Dry-run] ' : ''}${app.installed ? 'Desinstalação' : 'Instalação'} de ${app.name}.`, 'info');
            });
            fragment.appendChild(card);
        });
        dom.appListContainer.appendChild(fragment);
    }

    function renderSystemInfo() {
        if (!dom.systemInfoContainer) return;
        const info = state.systemInfo;
        const cards = [
            ['CPU', info.cpu || info.CPUName || 'N/A'],
            ['GPU', info.gpu || info.GPUName || 'N/A'],
            ['RAM', info.ram || (info.RAMGB ? `${info.RAMGB} GB` : 'N/A')],
            ['Sistema', info.os || 'N/A'],
            ['Classe HW', info.hardwareClass || 'N/A'],
            ['Admin', info.isAdmin === undefined ? 'N/A' : (info.isAdmin ? 'Sim' : 'Não')],
            ['Disco', info.diskType || info.DiskType || 'N/A'],
            ['Rede', info.networkAdapter || 'N/A']
        ];
        dom.systemInfoContainer.innerHTML = cards
            .map(([title, value]) => `<div class="tweak-card glassmorphism"><h3>${title}</h3><p>${value}</p></div>`)
            .join('');
    }

    function renderContent() {
        if (state.activeCategory === 'Jogos') {
            renderCategories();
            renderGames();
            return;
        }
        if (state.activeCategory === 'Apps Essenciais') {
            renderCategories();
            renderApps();
            return;
        }
        renderCategories();
        renderTweaks();
    }

    function renderAll() {
        renderSystemInfo();
        renderContent();
        renderLogs();
    }

    function createSnapshot() {
        const snapshot = {
            createdAt: new Date().toISOString(),
            mode: state.mode,
            tweaks: state.tweaks.map(t => ({ id: t.id, status: t.status }))
        };
        state.snapshots.push(snapshot);
        if (state.snapshots.length > 20) state.snapshots.shift();
        localStorage.setItem('linaoptimizer_snapshots', JSON.stringify(state.snapshots));
        logEvent('info', 'snapshot_created', { count: state.snapshots.length });
        showToast('Snapshot criado com sucesso.', 'success');
    }

    function rollbackAll() {
        if (state.dryRun) {
            logEvent('info', 'dry_run_rollback_all', {});
            showToast('[Dry-run] Rollback global simulado.', 'info');
            return;
        }
        state.tweaks.forEach(t => {
            t.status = false;
            state.appliedTweaks.delete(t.id);
        });
        logEvent('warn', 'rollback_all', { total: state.tweaks.length });
        showToast('Rollback global aplicado.', 'warning');
        renderContent();
    }

    function applyRecommended() {
        const recommended = state.tweaks.filter(t => normalizeRisk(t.risk).className !== 'high');
        if (state.dryRun) {
            showToast(`[Dry-run] ${recommended.length} tweaks recomendados seriam aplicados.`, 'info');
            logEvent('info', 'dry_run_apply_recommended', { count: recommended.length });
            return;
        }
        recommended.forEach(t => {
            t.status = true;
            state.appliedTweaks.set(t.id, true);
        });
        logEvent('info', 'apply_recommended', { count: recommended.length });
        showToast(`${recommended.length} tweaks recomendados ativados.`, 'success');
        renderContent();
    }

    function bindEvents() {
        dom.searchInput?.addEventListener('input', () => renderContent());
        dom.modeSelect?.addEventListener('change', e => {
            state.mode = e.target.value;
            logEvent('info', 'mode_changed', { mode: state.mode });
            showToast(`Modo alterado para ${state.mode.toUpperCase()}.`, 'info');
            renderContent();
        });
        dom.dryRunToggle?.addEventListener('change', e => {
            state.dryRun = Boolean(e.target.checked);
            logEvent('info', 'dry_run_changed', { dryRun: state.dryRun });
        });
        dom.rollbackAllBtn?.addEventListener('click', rollbackAll);
        dom.snapshotBtn?.addEventListener('click', createSnapshot);
        dom.restorePointBtn?.addEventListener('click', createSnapshot);
        dom.activateBtn?.addEventListener('click', applyRecommended);
        dom.exportLogsBtn?.addEventListener('click', () => {
            const blob = new Blob([JSON.stringify(state.logs, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `linaoptimizer-logs-${Date.now()}.json`;
            a.click();
            URL.revokeObjectURL(url);
        });

        if (dom.langPtBtn && dom.langEnBtn) {
            const setLang = lang => {
                state.lang = lang;
                dom.langPtBtn.classList.toggle('active', lang === 'pt');
                dom.langEnBtn.classList.toggle('active', lang === 'en');
                logEvent('info', 'lang_changed', { lang });
            };
            dom.langPtBtn.addEventListener('click', () => setLang('pt'));
            dom.langEnBtn.addEventListener('click', () => setLang('en'));
        }
    }

    function bootstrap() {
        try {
            state.snapshots = JSON.parse(localStorage.getItem('linaoptimizer_snapshots') || '[]');
        } catch {
            state.snapshots = [];
        }
        bindEvents();
        fetchAllData();
    }

    bootstrap();
});
