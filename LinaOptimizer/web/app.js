// Encoding: UTF-8 with BOM

document.addEventListener('DOMContentLoaded', () => {
    const el = {
        categoryPicker: document.getElementById('category-picker'),
        tweakList: document.getElementById('tweak-list-container') || document.getElementById('tweak-grid'),
        systemInfo: document.getElementById('system-info-container') || document.querySelector('.system-info-grid'),
        games: document.getElementById('game-list-container') || document.getElementById('games-grid'),
        apps: document.getElementById('app-list-container') || document.getElementById('apps-grid'),
        restoreBtn: document.getElementById('create-restore-point-btn') || document.getElementById('create-restore-point'),
        ptBtn: document.getElementById('lang-pt'),
        enBtn: document.getElementById('lang-en'),
        toast: document.getElementById('toast-container')
    };

    const state = {
        lang: 'pt',
        mode: 'safe',
        dryRun: true,
        currentCategory: 'Sistema',
        tweaks: [],
        games: [],
        apps: [],
        systemInfo: {},
        appliedTweaks: new Map(),
        logs: [],
        snapshot: null
    };

    const modePolicy = {
        safe: { allowHighRisk: false, label: 'Modo Seguro' },
        extreme: { allowHighRisk: true, label: 'Modo Extremo' },
        insane: { allowHighRisk: true, label: 'Modo Insano' }
    };

    const fallbackTweaks = [
        { id: 'DisableTelemetry', name: 'Desativar Telemetria', description: 'Reduz coleta de dados e processos em segundo plano.', category: 'Privacidade', risk: 'Baixo', module: 'System', rebootRequired: false, version: '1.0.0', dependencies: [] },
        { id: 'OptimizeNetwork', name: 'Otimizar Rede', description: 'Ajusta TCP e stack de rede para menor latência.', category: 'Rede', risk: 'Médio', module: 'Network', rebootRequired: false, version: '1.0.0', dependencies: [] },
        { id: 'SetPowerPlanUltimate', name: 'Ultimate Performance', description: 'Força plano de energia focado em desempenho.', category: 'Energia', risk: 'Médio', module: 'Power', rebootRequired: false, version: '1.0.0', dependencies: [] },
        { id: 'DisableCoreIsolation', name: 'Desativar Isolamento de Núcleo', description: 'Aumenta desempenho e reduz segurança.', category: 'Segurança', risk: 'Alto', module: 'Kernel', rebootRequired: true, version: '1.0.0', dependencies: ['SetPowerPlanUltimate'], warning: 'Alto risco: reduz proteção do Windows.' },
        { id: 'DisableSpectreMitigation', name: 'Desativar Mitigações Spectre', description: 'Melhora benchmark em troca de segurança.', category: 'Kernel', risk: 'Alto', module: 'Kernel', rebootRequired: true, version: '1.0.0', dependencies: ['DisableCoreIsolation'], warning: 'Use apenas para benchmark offline.' },
        { id: 'DisableBackgroundApps', name: 'Bloquear Apps em Segundo Plano', description: 'Reduz consumo de RAM e CPU idle.', category: 'Sistema', risk: 'Baixo', module: 'System', rebootRequired: false, version: '1.0.0', dependencies: [] },
        { id: 'DisableGameBar', name: 'Desativar Xbox Game Bar', description: 'Remove overlay para reduzir input lag.', category: 'Jogos', risk: 'Baixo', module: 'System', rebootRequired: false, version: '1.0.0', dependencies: [] },
        { id: 'DisableHPET', name: 'Desativar HPET', description: 'Pode melhorar latência em alguns cenários.', category: 'Kernel', risk: 'Médio', module: 'Kernel', rebootRequired: true, version: '1.0.0', dependencies: [] }
    ];

    const fallbackGames = [
        { id: 'CS2', name: 'Counter-Strike 2', description: 'Perfil para latência mínima.', detected: false },
        { id: 'Valorant', name: 'Valorant', description: 'Perfil competitivo estável.', detected: false },
        { id: 'Fortnite', name: 'Fortnite', description: 'Perfil para frame time estável.', detected: false }
    ];

    const fallbackApps = [
        { id: 'Discord', name: 'Discord', description: 'Comunicação.', icon: '🎙️', installed: false },
        { id: 'OBS', name: 'OBS Studio', description: 'Streaming e captura.', icon: '📹', installed: false },
        { id: 'MSIAfterburner', name: 'MSI Afterburner', description: 'Monitoramento e tuning.', icon: '⚙️', installed: false }
    ];

    function toast(message, type = 'info') {
        if (!el.toast) return;
        const box = document.createElement('div');
        box.className = `toast ${type}`;
        box.textContent = message;
        el.toast.appendChild(box);
        setTimeout(() => box.remove(), 3200);
    }

    function log(event, payload = {}) {
        const entry = { ts: new Date().toISOString(), event, payload, mode: state.mode, dryRun: state.dryRun };
        state.logs.push(entry);
        if (state.logs.length > 500) state.logs.shift();
        localStorage.setItem('linaoptimizer.logs.json', JSON.stringify(state.logs));
        console.log('[LinaLog]', entry);
    }

    function riskClass(risk = 'Baixo') {
        const n = risk.toLowerCase();
        if (n.includes('alto') || n.includes('high')) return 'high';
        if (n.includes('médio') || n.includes('medio') || n.includes('medium')) return 'medium';
        return 'low';
    }

    function computeScores(info) {
        const ramValue = parseInt(String(info.ram || '').replace(/\D/g, ''), 10) || 8;
        const cpuScore = info.cpu && !String(info.cpu).includes('N/A') ? 75 : 40;
        const gpuScore = info.gpu && !String(info.gpu).includes('N/A') ? 75 : 40;
        const ramScore = Math.min(100, Math.max(35, Math.round((ramValue / 32) * 100)));
        const diskScore = info.diskType === 'SSD' || info.diskType === 'NVMe' ? 85 : 55;
        const netScore = info.network ? 80 : 60;
        const overall = Math.round((cpuScore + gpuScore + ramScore + diskScore + netScore) / 5);

        let profile = 'LOW';
        if (overall >= 80) profile = 'HIGH';
        if (overall >= 90) profile = 'EXTREME';
        if (overall >= 60 && overall < 80) profile = 'MID';

        return { overall, cpuScore, gpuScore, ramScore, diskScore, netScore, profile };
    }

    async function requestJson(url, fallback) {
        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            log('fetch_error', { url, error: String(error) });
            return fallback;
        }
    }

    async function fetchAllData() {
        const [tweaksRes, gamesRes, appsRes, sysRes] = await Promise.all([
            requestJson('/api/tweaks', { tweaks: fallbackTweaks }),
            requestJson('/api/games', { games: fallbackGames }),
            requestJson('/api/apps', { apps: fallbackApps }),
            requestJson('/api/system-info', { cpu: 'N/A', gpu: 'N/A', ram: '8 GB', os: 'Windows 10/11' })
        ]);

        state.tweaks = tweaksRes.tweaks || fallbackTweaks;
        state.games = gamesRes.games || fallbackGames;
        state.apps = appsRes.apps || fallbackApps;
        state.systemInfo = sysRes.systemInfo || sysRes;

        state.snapshot = {
            createdAt: new Date().toISOString(),
            mode: state.mode,
            dryRun: state.dryRun,
            applied: Array.from(state.appliedTweaks.keys())
        };

        log('boot', {
            tweaks: state.tweaks.length,
            games: state.games.length,
            apps: state.apps.length
        });

        renderSystemInfo();
        renderModeBar();
        renderCategoryPicker();
        renderContent();
    }

    function renderModeBar() {
        const section = document.querySelector('#tweaks-section');
        if (!section) return;

        const existing = document.getElementById('runtime-controls');
        if (existing) existing.remove();

        const panel = document.createElement('div');
        panel.id = 'runtime-controls';
        panel.style.display = 'flex';
        panel.style.flexWrap = 'wrap';
        panel.style.gap = '10px';
        panel.style.marginBottom = '12px';

        const modeSelect = document.createElement('select');
        modeSelect.innerHTML = `
            <option value="safe">Modo Seguro</option>
            <option value="extreme">Modo Extremo</option>
            <option value="insane">Modo Insano</option>
        `;
        modeSelect.value = state.mode;
        modeSelect.addEventListener('change', () => {
            state.mode = modeSelect.value;
            log('mode_changed', { mode: state.mode });
            toast(`Modo alterado para ${modePolicy[state.mode].label}`, 'info');
        });

        const dryRunBtn = document.createElement('button');
        dryRunBtn.textContent = state.dryRun ? 'DRY-RUN: ON' : 'DRY-RUN: OFF';
        dryRunBtn.className = 'btn-secondary';
        dryRunBtn.style.padding = '8px 12px';
        dryRunBtn.addEventListener('click', () => {
            state.dryRun = !state.dryRun;
            dryRunBtn.textContent = state.dryRun ? 'DRY-RUN: ON' : 'DRY-RUN: OFF';
            log('dryrun_toggled', { dryRun: state.dryRun });
        });

        const rollbackBtn = document.createElement('button');
        rollbackBtn.textContent = 'ROLLBACK GLOBAL';
        rollbackBtn.className = 'btn-secondary';
        rollbackBtn.style.padding = '8px 12px';
        rollbackBtn.addEventListener('click', rollbackAllTweaks);

        const search = document.createElement('input');
        search.type = 'search';
        search.placeholder = 'Buscar tweak...';
        search.style.padding = '8px 10px';
        search.style.borderRadius = '8px';
        search.style.border = '1px solid var(--border-color)';
        search.style.background = 'var(--bg-medium)';
        search.style.color = 'var(--text-light)';
        search.addEventListener('input', () => renderTweaks(state.currentCategory, search.value));

        panel.append(modeSelect, dryRunBtn, rollbackBtn, search);
        section.insertBefore(panel, section.querySelector('.category-picker'));
    }

    function renderCategoryPicker() {
        if (!el.categoryPicker) return;
        const categories = [...new Set(state.tweaks.map(t => t.category).filter(Boolean))];
        const tabs = [...new Set([...categories, 'Jogos', 'Apps Essenciais'])];
        if (!tabs.includes(state.currentCategory)) state.currentCategory = tabs[0] || 'Sistema';

        el.categoryPicker.innerHTML = '';
        for (const category of tabs) {
            const count = category === 'Jogos' ? state.games.length : category === 'Apps Essenciais' ? state.apps.length : state.tweaks.filter(t => t.category === category).length;
            const btn = document.createElement('button');
            btn.className = `category-tab ${state.currentCategory === category ? 'active' : ''}`;
            btn.innerHTML = `${category} <span class="badge">${count}</span>`;
            btn.addEventListener('click', () => {
                state.currentCategory = category;
                renderCategoryPicker();
                renderContent();
            });
            el.categoryPicker.appendChild(btn);
        }
    }

    function renderContent() {
        document.querySelectorAll('.content-section').forEach(section => section.classList.remove('active'));
        if (state.currentCategory === 'Jogos') {
            document.getElementById('games-section')?.classList.add('active');
            renderGames();
            return;
        }
        if (state.currentCategory === 'Apps Essenciais') {
            document.getElementById('apps-section')?.classList.add('active');
            renderApps();
            return;
        }
        document.getElementById('tweaks-section')?.classList.add('active');
        renderTweaks(state.currentCategory);
    }

    function dependencyMissing(tweak) {
        const deps = tweak.dependencies || [];
        return deps.find(depId => !state.appliedTweaks.has(depId));
    }

    function toggleTweak(tweak, checked) {
        if (checked) {
            const missing = dependencyMissing(tweak);
            if (missing) {
                toast(`Dependência ausente: ${missing}`, 'error');
                return false;
            }

            if (!modePolicy[state.mode].allowHighRisk && riskClass(tweak.risk) === 'high') {
                toast('Tweak de alto risco bloqueado no Modo Seguro.', 'warning');
                return false;
            }

            if (riskClass(tweak.risk) === 'high') {
                const step1 = confirm(`ATENÇÃO: ${tweak.name} é de alto risco. Deseja continuar?`);
                if (!step1) return false;
                const step2 = confirm('Confirmação final: você entende os riscos?');
                if (!step2) return false;
            }

            if (!state.dryRun) {
                // ponto de integração real com backend /api/apply-tweak
            }

            state.appliedTweaks.set(tweak.id, { appliedAt: new Date().toISOString(), snapshot: state.snapshot });
            log('tweak_applied', { id: tweak.id, category: tweak.category, dryRun: state.dryRun });
            return true;
        }

        state.appliedTweaks.delete(tweak.id);
        log('tweak_rollback', { id: tweak.id, dryRun: state.dryRun });
        return true;
    }

    function rollbackAllTweaks() {
        const count = state.appliedTweaks.size;
        state.appliedTweaks.clear();
        log('rollback_global', { count });
        toast(`Rollback global executado (${count} tweaks).`, 'success');
        renderTweaks(state.currentCategory);
    }

    function renderTweaks(category, search = '') {
        if (!el.tweakList) return;
        const q = search.trim().toLowerCase();
        const list = state.tweaks.filter(t => t.category === category && (!q || `${t.name} ${t.description}`.toLowerCase().includes(q)));

        el.tweakList.innerHTML = '';
        if (list.length === 0) {
            el.tweakList.innerHTML = '<p style="text-align:center;color:#999;">Nenhum tweak nesta categoria.</p>';
            return;
        }

        const fragment = document.createDocumentFragment();
        for (const tweak of list) {
            const risk = riskClass(tweak.risk);
            const active = state.appliedTweaks.has(tweak.id);
            const card = document.createElement('div');
            card.className = 'tweak-card glassmorphism';
            card.innerHTML = `
                <div class="tweak-header">
                    <h3>${tweak.name}</h3>
                    <div class="status-toggle">
                        <label>
                            <input type="checkbox" ${active ? 'checked' : ''}>
                            <span class="slider"></span>
                        </label>
                    </div>
                </div>
                <p>${tweak.description}</p>
                <div class="tweak-meta">
                    <span class="risk-badge ${risk}">${tweak.risk || 'Baixo'}</span>
                    <span style="font-size:.8em;color:#aaa;">v${tweak.version || '1.0.0'}</span>
                    ${tweak.rebootRequired ? '<span class="reboot-required">Reinício Necessário</span>' : ''}
                </div>
                ${tweak.warning ? `<p style="color:#ff9f9f;font-size:.85em;"><strong>Aviso:</strong> ${tweak.warning}</p>` : ''}
            `;

            const checkbox = card.querySelector('input[type="checkbox"]');
            checkbox.addEventListener('change', () => {
                const ok = toggleTweak(tweak, checkbox.checked);
                if (!ok) checkbox.checked = false;
            });

            fragment.appendChild(card);
        }
        el.tweakList.appendChild(fragment);
    }

    function renderGames() {
        if (!el.games) return;
        el.games.innerHTML = '';
        const fragment = document.createDocumentFragment();
        for (const game of state.games) {
            const card = document.createElement('div');
            card.className = 'game-card glassmorphism';
            card.innerHTML = `
                <h3>${game.name}</h3>
                <p>${game.description}</p>
                <div class="game-status ${game.detected ? 'detected' : 'not-found'}">${game.detected ? '✓ DETECTADO' : '✗ NÃO ENCONTRADO'}</div>
                <button class="btn-apply-game">APLICAR PERFIL</button>
            `;
            card.querySelector('.btn-apply-game').addEventListener('click', () => {
                log('game_profile_applied', { gameId: game.id });
                toast(`Perfil aplicado para ${game.name}.`, 'success');
            });
            fragment.appendChild(card);
        }
        el.games.appendChild(fragment);
    }

    function renderApps() {
        if (!el.apps) return;
        el.apps.innerHTML = '';
        const fragment = document.createDocumentFragment();
        for (const app of state.apps) {
            const card = document.createElement('div');
            card.className = 'app-card glassmorphism';
            card.innerHTML = `
                <div class="app-icon">${app.icon || '📦'}</div>
                <h3>${app.name}</h3>
                <p>${app.description}</p>
                <button>${app.installed ? 'DESINSTALAR' : 'INSTALAR'}</button>
            `;
            fragment.appendChild(card);
        }
        el.apps.appendChild(fragment);
    }

    function renderSystemInfo() {
        if (!el.systemInfo) return;
        const info = state.systemInfo || {};
        const s = computeScores(info);

        el.systemInfo.innerHTML = `
            <div class="tweak-card glassmorphism"><h3>CPU</h3><p>${info.cpu || 'N/A'}</p></div>
            <div class="tweak-card glassmorphism"><h3>GPU</h3><p>${info.gpu || 'N/A'}</p></div>
            <div class="tweak-card glassmorphism"><h3>RAM</h3><p>${info.ram || 'N/A'}</p></div>
            <div class="tweak-card glassmorphism"><h3>SO</h3><p>${info.os || 'Windows 10/11'}</p></div>
            <div class="tweak-card glassmorphism"><h3>SCORE GERAL</h3><p>${s.overall}/100 (${s.profile})</p></div>
            <div class="tweak-card glassmorphism"><h3>Scores</h3><p>CPU ${s.cpuScore} | GPU ${s.gpuScore} | RAM ${s.ramScore} | Disco ${s.diskScore} | Rede ${s.netScore}</p></div>
        `;
    }

    function setupActions() {
        el.restoreBtn?.addEventListener('click', () => {
            state.snapshot = {
                createdAt: new Date().toISOString(),
                mode: state.mode,
                dryRun: state.dryRun,
                applied: Array.from(state.appliedTweaks.keys())
            };
            log('snapshot_created', state.snapshot);
            toast('Snapshot de segurança criado.', 'success');
        });

        if (el.ptBtn && el.enBtn) {
            const setLang = (lang) => {
                state.lang = lang;
                el.ptBtn.classList.toggle('active', lang === 'pt');
                el.enBtn.classList.toggle('active', lang === 'en');
                log('language_changed', { lang });
            };
            el.ptBtn.addEventListener('click', () => setLang('pt'));
            el.enBtn.addEventListener('click', () => setLang('en'));
        }
    }

    setupActions();
    fetchAllData();
});
