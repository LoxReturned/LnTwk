// Encoding: UTF-8 with BOM

document.addEventListener('DOMContentLoaded', () => {
    const $ = (id) => document.getElementById(id);

    const dom = {
        categoryPicker: $('category-picker'),
        tweakList: $('tweak-list-container'),
        gamesList: $('game-list-container'),
        appsList: $('app-list-container'),
        systemInfo: $('system-info-container'),
        searchInput: $('search-input'),
        modeSelect: $('mode-select'),
        dryRunToggle: $('dry-run-toggle'),
        logsOutput: $('logs-output'),
        scoreOverall: $('score-overall'),
        scoreDetail: $('score-detail'),
        tweaksSection: $('tweaks-section'),
        gamesSection: $('games-section'),
        appsSection: $('apps-section'),
        btnApplyRecommended: $('activate-optimizations'),
        btnSnapshot: $('snapshot-btn'),
        btnRollbackAll: $('rollback-all-btn'),
        btnRestorePoint: $('create-restore-point-btn'),
        btnExportLogs: $('export-logs-btn'),
        langPt: $('lang-pt'),
        langEn: $('lang-en')
    };

    const state = {
        lang: 'pt',
        mode: 'safe',
        dryRun: false,
        activeCategory: 'Sistema',
        tweaks: [],
        games: [],
        apps: [],
        systemInfo: {},
        logs: [],
        snapshots: JSON.parse(localStorage.getItem('linaoptimizer_snapshots') || '[]'),
        apiBase: '',
        apiResolved: false
    };

    const fallback = {
        tweaks: [
            { id: 'DisableTelemetry', name: 'Desativar Telemetria', description: 'Reduz coleta de dados.', category: 'Privacidade', risk: 'Baixo', rebootRequired: false, status: false },
            { id: 'OptimizeNetwork', name: 'Otimizar Rede', description: 'Reduz latência de rede.', category: 'Rede', risk: 'Baixo', rebootRequired: false, status: false },
            { id: 'DisableHPET', name: 'Desativar HPET', description: 'Pode reduzir latência.', category: 'Kernel', risk: 'Médio', rebootRequired: true, status: false },
            { id: 'DisableCoreIsolation', name: 'Desativar Core Isolation', description: 'Aumenta desempenho com risco de segurança.', category: 'Segurança', risk: 'Alto', rebootRequired: true, status: false, warning: 'Use só se entender os riscos.' }
        ],
        games: [
            { id: 'CS2', name: 'Counter-Strike 2', description: 'Perfil competitivo', detected: false },
            { id: 'Valorant', name: 'Valorant', description: 'Perfil baixa latência', detected: false }
        ],
        apps: [
            { id: 'Discord', name: 'Discord', description: 'Comunicação', icon: '🎙️', installed: false },
            { id: 'OBSStudio', name: 'OBS Studio', description: 'Streaming', icon: '📹', installed: false }
        ],
        systemInfo: { os: 'Windows', cpu: 'N/A', gpu: 'N/A', ram: 'N/A', scores: { overall: 0, cpu: 0, gpu: 0, ram: 0, disk: 0, network: 0 } }
    };

    const categorySpecial = ['Jogos', 'Apps Essenciais'];

    function log(level, action, data = {}) {
        const row = {
            ts: new Date().toISOString(),
            level,
            action,
            mode: state.mode,
            dryRun: state.dryRun,
            data
        };
        state.logs.push(row);
        if (state.logs.length > 200) state.logs.shift();
        dom.logsOutput.textContent = state.logs.slice(-30).map(i => `[${i.ts}] [${i.level.toUpperCase()}] ${i.action} ${JSON.stringify(i.data)}`).join('\n');
    }

    async function resolveApiBase() {
        if (state.apiResolved) return;

        const candidates = [''];
        if (window.location.port !== '8080') {
            candidates.push('http://127.0.0.1:8080', 'http://localhost:8080');
        }

        for (const base of candidates) {
            try {
                const r = await fetch(`${base}/api/system-info`, { method: 'GET' });
                if (r.ok) {
                    state.apiBase = base;
                    state.apiResolved = true;
                    log('info', 'api_base_resolved', { base: base || 'same-origin' });
                    return;
                }
            } catch {
                // tenta próximo candidato
            }
        }

        state.apiBase = '';
        state.apiResolved = true;
        log('warn', 'api_base_unresolved', { mode: 'fallback_only' });
    }

    async function api(url, options = {}, fallbackData) {
        await resolveApiBase();

        const candidates = state.apiBase ? [`${state.apiBase}${url}`, url] : [url];
        let lastError = null;

        for (const target of candidates) {
            try {
                const res = await fetch(target, options);
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                return await res.json();
            } catch (e) {
                lastError = e;
            }
        }

        log('warn', 'api_fallback', { url, error: lastError ? lastError.message : 'unknown' });
        return fallbackData;
    }

    function riskMeta(risk) {
        const key = String(risk || '').toLowerCase();
        if (key.includes('alto') || key.includes('high')) return { label: 'Alto', css: 'risk-high' };
        if (key.includes('médio') || key.includes('medio') || key.includes('medium')) return { label: 'Médio', css: 'risk-medium' };
        return { label: 'Baixo', css: 'risk-low' };
    }

    function getCategories() {
        const fromData = [...new Set(state.tweaks.map(t => t.category).filter(Boolean))];
        return [...fromData, ...categorySpecial.filter(c => !fromData.includes(c))];
    }

    function setSection(section) {
        dom.tweaksSection.classList.add('hidden');
        dom.gamesSection.classList.add('hidden');
        dom.appsSection.classList.add('hidden');
        if (section === 'games') dom.gamesSection.classList.remove('hidden');
        else if (section === 'apps') dom.appsSection.classList.remove('hidden');
        else dom.tweaksSection.classList.remove('hidden');
    }

    function renderCategories() {
        const categories = getCategories();
        if (!categories.includes(state.activeCategory)) state.activeCategory = categories[0] || 'Sistema';
        dom.categoryPicker.innerHTML = '';

        const frag = document.createDocumentFragment();
        categories.forEach(cat => {
            const b = document.createElement('button');
            b.textContent = cat;
            b.className = state.activeCategory === cat ? 'active' : '';
            b.addEventListener('click', () => {
                state.activeCategory = cat;
                render();
            });
            frag.appendChild(b);
        });
        dom.categoryPicker.appendChild(frag);
    }

    function renderSystemInfo() {
        const info = state.systemInfo || {};
        const cards = [
            ['Sistema', info.os || 'N/A'],
            ['CPU', info.cpu || 'N/A'],
            ['GPU', info.gpu || 'N/A'],
            ['RAM', info.ram || 'N/A'],
            ['Build', info.build || 'N/A'],
            ['Classe', info.hardwareClass || 'N/A'],
            ['Rede', info.networkAdapter || 'N/A'],
            ['Disco', info.diskType || 'N/A']
        ];
        dom.systemInfo.innerHTML = cards.map(([k, v]) => `<div class="card"><strong>${k}</strong><div class="muted">${v}</div></div>`).join('');

        const scores = info.scores || {};
        dom.scoreOverall.textContent = `${scores.overall ?? '--'}`;
        dom.scoreDetail.textContent = `CPU ${scores.cpu ?? '--'} | GPU ${scores.gpu ?? '--'} | RAM ${scores.ram ?? '--'} | Disco ${scores.disk ?? '--'} | Rede ${scores.network ?? '--'}`;
    }

    function filteredTweaks() {
        const q = dom.searchInput.value.trim().toLowerCase();
        return state.tweaks
            .filter(t => t.category === state.activeCategory)
            .filter(t => !q || `${t.name} ${t.description} ${t.category}`.toLowerCase().includes(q));
    }

    async function applyTweakRemote(tweakId, enabled) {
        const endpoint = enabled ? '/api/apply-tweak' : '/api/revert-tweak';
        const body = JSON.stringify({ tweakId });
        return await api(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body }, { success: false, message: 'fallback' });
    }

    function renderTweaks() {
        setSection('tweaks');
        const items = filteredTweaks();
        if (items.length === 0) {
            dom.tweakList.innerHTML = '<div class="card">Nenhum tweak nessa categoria/filtro.</div>';
            return;
        }

        const frag = document.createDocumentFragment();
        items.forEach(t => {
            const risk = riskMeta(t.risk);
            const el = document.createElement('article');
            el.className = 'card tweak-card';
            el.innerHTML = `
                <div class="row">
                    <h3>${t.name}</h3>
                    <input class="switch" type="checkbox" ${t.status ? 'checked' : ''}>
                </div>
                <p>${t.description || ''}</p>
                ${t.warning ? `<p><strong>Aviso:</strong> ${t.warning}</p>` : ''}
                <div class="row">
                    <span class="badge ${risk.css}">${risk.label}</span>
                    <span class="muted">${t.rebootRequired ? 'Reinício necessário' : 'Sem reinício'}</span>
                </div>
            `;

            const sw = el.querySelector('.switch');
            sw.addEventListener('change', async () => {
                if (risk.css === 'risk-high' && state.mode === 'safe') {
                    sw.checked = false;
                    log('warn', 'blocked_high_risk_in_safe_mode', { id: t.id });
                    return;
                }

                if (state.dryRun) {
                    sw.checked = t.status;
                    log('info', 'dry_run_toggle_tweak', { id: t.id, desired: !t.status });
                    return;
                }

                const desired = sw.checked;
                const remote = await applyTweakRemote(t.id, desired);
                if (remote.success === false) {
                    sw.checked = !desired;
                    log('error', 'remote_tweak_failed', { id: t.id, message: remote.message });
                    return;
                }
                t.status = desired;
                log('info', desired ? 'tweak_applied' : 'tweak_reverted', { id: t.id });
            });

            frag.appendChild(el);
        });
        dom.tweakList.innerHTML = '';
        dom.tweakList.appendChild(frag);
    }

    function renderGames() {
        setSection('games');
        dom.gamesList.innerHTML = '';
        const frag = document.createDocumentFragment();
        state.games.forEach(g => {
            const el = document.createElement('article');
            el.className = 'card';
            el.innerHTML = `
                <h3 style="margin:0 0 8px">${g.name}</h3>
                <p>${g.description || ''}</p>
                <div class="row"><span class="badge ${g.detected ? 'risk-low' : 'risk-medium'}">${g.detected ? 'Detectado' : 'Não detectado'}</span>
                <button>Aplicar Perfil</button></div>
            `;
            el.querySelector('button').addEventListener('click', async () => {
                if (state.dryRun) {
                    log('info', 'dry_run_game_apply', { gameId: g.id, mode: state.mode });
                    return;
                }
                const res = await api('/api/apply-game-tweak', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ gameId: g.id, intensity: state.mode === 'safe' ? 'light' : state.mode === 'extreme' ? 'medium' : 'heavy' })
                }, { success: false });
                log(res.success ? 'info' : 'error', 'game_apply', { gameId: g.id, result: res });
            });
            frag.appendChild(el);
        });
        dom.gamesList.appendChild(frag);
    }

    function renderApps() {
        setSection('apps');
        dom.appsList.innerHTML = '';
        const frag = document.createDocumentFragment();
        state.apps.forEach(a => {
            const el = document.createElement('article');
            el.className = 'card';
            el.innerHTML = `
                <h3 style="margin:0 0 8px">${a.icon || '📦'} ${a.name}</h3>
                <p>${a.description || ''}</p>
                <div class="row"><span class="badge ${a.installed ? 'risk-low' : 'risk-medium'}">${a.installed ? 'Instalado' : 'Não instalado'}</span>
                <button>${a.installed ? 'Reinstalar' : 'Instalar'}</button></div>
            `;
            el.querySelector('button').addEventListener('click', async () => {
                if (state.dryRun) {
                    log('info', 'dry_run_install_app', { appId: a.id });
                    return;
                }
                const res = await api('/api/install-app', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ appId: a.id })
                }, { success: false });
                log(res.success ? 'info' : 'error', 'install_app', { appId: a.id, result: res });
            });
            frag.appendChild(el);
        });
        dom.appsList.appendChild(frag);
    }

    function render() {
        renderCategories();
        if (state.activeCategory === 'Jogos') renderGames();
        else if (state.activeCategory === 'Apps Essenciais') renderApps();
        else renderTweaks();
    }

    function createSnapshot(kind = 'manual') {
        const snapshot = {
            ts: new Date().toISOString(),
            kind,
            mode: state.mode,
            tweaks: state.tweaks.map(t => ({ id: t.id, status: t.status }))
        };
        state.snapshots.push(snapshot);
        if (state.snapshots.length > 30) state.snapshots.shift();
        localStorage.setItem('linaoptimizer_snapshots', JSON.stringify(state.snapshots));
        log('info', 'snapshot_created', { kind, total: state.snapshots.length });
    }

    function rollbackAll() {
        if (state.dryRun) {
            log('warn', 'dry_run_rollback_all', {});
            return;
        }
        state.tweaks.forEach(t => { t.status = false; });
        log('warn', 'rollback_all', { total: state.tweaks.length });
        render();
    }

    async function loadData() {
        const [tRes, gRes, aRes, sRes] = await Promise.all([
            api('/api/tweaks', {}, { tweaks: fallback.tweaks }),
            api('/api/games', {}, { games: fallback.games }),
            api('/api/apps', {}, { apps: fallback.apps }),
            api('/api/system-info', {}, { systemInfo: fallback.systemInfo })
        ]);

        state.tweaks = (tRes.tweaks || fallback.tweaks).map(t => ({
            id: t.id,
            name: t.name || t.title || t.id,
            description: t.description || '',
            category: t.category || 'Sistema',
            risk: t.risk || 'Baixo',
            rebootRequired: Boolean(t.rebootRequired || t.needsRestart),
            warning: t.warning,
            status: Boolean(t.status)
        }));

        state.games = gRes.games || fallback.games;
        state.apps = aRes.apps || fallback.apps;
        state.systemInfo = sRes.systemInfo || sRes || fallback.systemInfo;

        renderSystemInfo();
        render();
        log('info', 'data_loaded', { tweaks: state.tweaks.length, games: state.games.length, apps: state.apps.length });
    }

    function bindEvents() {
        dom.searchInput.addEventListener('input', () => render());
        dom.modeSelect.addEventListener('change', () => {
            state.mode = dom.modeSelect.value;
            log('info', 'mode_changed', { mode: state.mode });
        });
        dom.dryRunToggle.addEventListener('change', () => {
            state.dryRun = dom.dryRunToggle.checked;
            log('info', 'dry_run_changed', { dryRun: state.dryRun });
        });

        dom.btnApplyRecommended.addEventListener('click', () => {
            const allowed = state.tweaks.filter(t => !riskMeta(t.risk).css.includes('high'));
            if (state.dryRun) {
                log('info', 'dry_run_apply_recommended', { total: allowed.length });
                return;
            }
            allowed.forEach(t => { t.status = true; });
            log('info', 'apply_recommended', { total: allowed.length });
            render();
        });

        dom.btnSnapshot.addEventListener('click', () => createSnapshot('manual'));
        dom.btnRollbackAll.addEventListener('click', rollbackAll);
        dom.btnRestorePoint.addEventListener('click', async () => {
            createSnapshot('pre-restore-point');
            if (state.dryRun) {
                log('info', 'dry_run_restore_point', {});
                return;
            }
            const res = await api('/api/create-restore-point', { method: 'POST' }, { success: false });
            log(res.success ? 'info' : 'error', 'create_restore_point', res);
        });

        dom.btnExportLogs.addEventListener('click', () => {
            const blob = new Blob([JSON.stringify(state.logs, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `linaoptimizer-logs-${Date.now()}.json`;
            a.click();
            URL.revokeObjectURL(url);
        });

        dom.langPt.addEventListener('click', () => {
            state.lang = 'pt';
            dom.langPt.classList.add('active');
            dom.langEn.classList.remove('active');
            log('info', 'lang', { lang: 'pt' });
        });
        dom.langEn.addEventListener('click', () => {
            state.lang = 'en';
            dom.langEn.classList.add('active');
            dom.langPt.classList.remove('active');
            log('info', 'lang', { lang: 'en' });
        });
    }

    bindEvents();
    loadData();
});
