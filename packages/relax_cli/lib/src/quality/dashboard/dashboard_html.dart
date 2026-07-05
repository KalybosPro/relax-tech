/// The self-contained dashboard single-page app, served at `/`.
///
/// Vanilla HTML/CSS/JS with no external dependencies (per the spec: a static
/// bundle that ships with the CLI). It fetches `/api/report` once and renders
/// every panel client-side; it never recalculates a score.
library;

const String dashboardHtml = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>relax quality</title>
<style>
  :root {
    --bg: #0f1115; --panel: #171a21; --panel-2: #1e222b; --border: #272c37;
    --text: #e6e9ef; --muted: #8b93a7; --accent: #4f9cf9;
    --good: #3fb950; --warn: #d29922; --bad: #f85149; --info: #6e7681;
  }
  @media (prefers-color-scheme: light) {
    :root {
      --bg: #f6f7f9; --panel: #ffffff; --panel-2: #f0f2f5; --border: #e2e5ea;
      --text: #1a1d24; --muted: #616a7a; --accent: #1f6feb;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: var(--bg); color: var(--text);
    font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  a { color: var(--accent); }
  header {
    display: flex; align-items: center; gap: 24px; flex-wrap: wrap;
    padding: 24px 28px; border-bottom: 1px solid var(--border); background: var(--panel);
  }
  header .brand { font-size: 20px; font-weight: 700; letter-spacing: -.02em; }
  header .brand small { color: var(--muted); font-weight: 400; margin-left: 8px; font-size: 13px; }
  header .meta { color: var(--muted); font-size: 13px; margin-left: auto; text-align: right; }
  .gauge { position: relative; width: 108px; height: 108px; }
  .gauge svg { transform: rotate(-90deg); }
  .gauge .val { position: absolute; inset: 0; display: flex; flex-direction: column;
    align-items: center; justify-content: center; }
  .gauge .val b { font-size: 26px; }
  .gauge .val span { font-size: 11px; color: var(--muted); }
  main { padding: 24px 28px; display: grid; gap: 18px;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); align-items: start; }
  .panel { background: var(--panel); border: 1px solid var(--border); border-radius: 12px; padding: 18px 20px; }
  .panel.wide { grid-column: 1 / -1; }
  .panel h2 { margin: 0 0 14px; font-size: 13px; text-transform: uppercase;
    letter-spacing: .06em; color: var(--muted); font-weight: 600; }
  .row { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 6px 0; }
  .row + .row { border-top: 1px solid var(--border); }
  .badge { display: inline-flex; align-items: center; gap: 6px; padding: 5px 10px;
    border-radius: 999px; font-size: 12px; font-weight: 600; }
  .badge::before { content: ""; width: 8px; height: 8px; border-radius: 50%; background: currentColor; }
  .badges { display: flex; flex-wrap: wrap; gap: 10px; }
  .g { color: var(--good); background: color-mix(in srgb, var(--good) 14%, transparent); }
  .w { color: var(--warn); background: color-mix(in srgb, var(--warn) 14%, transparent); }
  .b { color: var(--bad); background: color-mix(in srgb, var(--bad) 14%, transparent); }
  .i { color: var(--muted); background: var(--panel-2); }
  .bar { height: 8px; border-radius: 4px; background: var(--panel-2); overflow: hidden; }
  .bar > i { display: block; height: 100%; border-radius: 4px; }
  .cov-row { display: grid; grid-template-columns: 120px 1fr 48px; gap: 12px; align-items: center; padding: 5px 0; }
  .cov-row .lbl { color: var(--muted); font-size: 13px; }
  .cov-row .pct { text-align: right; font-variant-numeric: tabular-nums; }
  .stat { display: flex; gap: 20px; }
  .stat div b { font-size: 24px; display: block; font-variant-numeric: tabular-nums; }
  .stat div span { color: var(--muted); font-size: 12px; }
  .heat { display: grid; grid-template-columns: repeat(auto-fill, minmax(96px, 1fr)); gap: 8px; }
  .cell { border-radius: 8px; padding: 12px 10px; color: #08130a; }
  .cell b { font-size: 18px; font-variant-numeric: tabular-nums; }
  .cell span { display: block; font-size: 11px; opacity: .85; }
  table { width: 100%; border-collapse: collapse; }
  th, td { text-align: left; padding: 6px 8px; border-bottom: 1px solid var(--border); font-size: 13px; }
  th { color: var(--muted); font-weight: 600; }
  td.n { text-align: right; font-variant-numeric: tabular-nums; }
  .muted { color: var(--muted); }
  .empty { color: var(--muted); font-style: italic; padding: 8px 0; }
  .sev { font-size: 11px; font-weight: 700; padding: 2px 7px; border-radius: 5px; }
  ul.list { list-style: none; margin: 0; padding: 0; }
  ul.list li { padding: 7px 0; border-top: 1px solid var(--border); }
  ul.list li:first-child { border-top: 0; }
  ul.list code { color: var(--muted); font-size: 12px; }
  #graph svg { width: 100%; height: auto; display: block; }
  #graph .node rect { fill: var(--panel-2); stroke: var(--border); rx: 6; cursor: pointer; }
  #graph .node text { fill: var(--text); font-size: 11px; }
  #graph .node.dim { opacity: .25; }
  #graph .edge { stroke: var(--info); fill: none; opacity: .35; }
  #graph .edge.hot { stroke: var(--accent); opacity: .95; }
  #graph .col-label { fill: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .05em; }
</style>
</head>
<body>
<header>
  <div class="gauge" id="gauge"></div>
  <div>
    <div class="brand">relax quality <small id="label"></small></div>
    <div class="muted" id="summary"></div>
    <div class="badges" id="sm" style="margin-top:8px"></div>
  </div>
  <div class="meta" id="meta"></div>
</header>
<main id="main"></main>

<script>
const LAYERS = ["widget","controller","usecase","repository","datasource","api_service","model","unknown"];
const el = (t, c, h) => { const e = document.createElement(t); if (c) e.className = c; if (h != null) e.innerHTML = h; return e; };
const covClass = p => p >= 70 ? "g" : p >= 40 ? "w" : "b";
const covColor = p => p >= 70 ? "var(--good)" : p >= 40 ? "var(--warn)" : "var(--bad)";
const scoreColor = s => s >= 75 ? "var(--good)" : s >= 50 ? "var(--warn)" : "var(--bad)";
const scoreLabel = s => s>=90?"Excellent":s>=75?"Good":s>=60?"Fair":s>=40?"Needs work":"Critical";
const panel = (title, body, wide) => { const p = el("section", "panel" + (wide?" wide":"")); p.appendChild(el("h2", null, title)); if (typeof body === "string") p.insertAdjacentHTML("beforeend", body); else if (body) p.appendChild(body); return p; };
const esc = s => String(s).replace(/[&<>]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]));

fetch("/api/report").then(r => r.json()).then(render).catch(e => {
  document.getElementById("main").innerHTML = '<section class="panel"><p class="empty">Failed to load report: ' + esc(e) + '</p></section>';
});

function render(rep) {
  drawGauge(rep.projectScore);
  document.getElementById("label").textContent = scoreLabel(rep.projectScore);
  const errs = rep.issues.filter(i => i.severity === "error").length;
  const warns = rep.issues.filter(i => i.severity === "warning").length;
  document.getElementById("summary").textContent =
    `${rep.filesAnalyzed} files · ${rep.violations.length} violations · ${errs} errors, ${warns} warnings · ${rep.testGaps.length} untested`;
  document.getElementById("meta").innerHTML =
    `schema ${rep.schemaVersion}<br>${new Date(rep.generatedAt).toLocaleString()}`;
  const sm = document.getElementById("sm");
  (rep.stateManagement || []).forEach(s => sm.appendChild(el("span", "badge i", esc(s))));

  const main = document.getElementById("main");
  main.appendChild(panel("Architecture", architecture(rep)));
  main.appendChild(panel("Coverage", coverage(rep)));
  main.appendChild(panel("Tests", tests(rep)));
  main.appendChild(panel("Violations", violations(rep)));
  main.appendChild(panel("Quality issues", issues(rep)));
  main.appendChild(panel("Missing tests", gaps(rep)));
  const heat = heatmap(rep); if (heat) main.appendChild(panel("Coverage heatmap", heat, true));
  const trendPanel = panel("Score history", el("p", "empty", "Loading…"), true);
  main.appendChild(trendPanel);
  main.appendChild(panel("Dependency graph", graph(rep), true));

  fetch("/api/history").then(r => r.json()).then(h => {
    const runs = (h.history || []);
    trendPanel.replaceChild(trend(runs), trendPanel.lastChild);
  }).catch(() => {});
}

function trend(runs) {
  if (runs.length < 2) {
    return el("p", "empty", runs.length ? "One run recorded — the trend appears after the next run." : "No history yet.");
  }
  const W = 900, H = 200, pad = 30, n = runs.length;
  const xs = i => pad + i * (W - pad * 2) / (n - 1);
  const ys = v => H - pad - (v / 100) * (H - pad * 2);
  const line = runs.map((r, i) => `${i ? "L" : "M"}${xs(i).toFixed(1)},${ys(r.projectScore).toFixed(1)}`).join(" ");
  const area = `${line} L${xs(n-1).toFixed(1)},${H-pad} L${xs(0).toFixed(1)},${H-pad} Z`;
  let dots = "";
  runs.forEach((r, i) => {
    dots += `<circle cx="${xs(i).toFixed(1)}" cy="${ys(r.projectScore).toFixed(1)}" r="3" fill="${scoreColor(r.projectScore)}">
      <title>${esc(new Date(r.timestamp).toLocaleString())} — score ${r.projectScore}${r.gitCommitSha ? " @ " + r.gitCommitSha.slice(0,7) : ""}</title></circle>`;
  });
  const grid = [0, 25, 50, 75, 100].map(v =>
    `<line x1="${pad}" y1="${ys(v)}" x2="${W-pad}" y2="${ys(v)}" stroke="var(--border)"/>
     <text x="4" y="${ys(v)+4}" fill="var(--muted)" font-size="10">${v}</text>`).join("");
  const last = runs[n-1].projectScore, first = runs[0].projectScore, delta = last - first;
  const wrap = el("div", null,
    `<div class="muted" style="margin-bottom:8px">${n} runs · ${delta>=0?"+":""}${delta} over range</div>
     <svg viewBox="0 0 ${W} ${H}" style="width:100%;height:auto">
       ${grid}
       <path d="${area}" fill="${scoreColor(last)}" opacity="0.08"/>
       <path d="${line}" fill="none" stroke="${scoreColor(last)}" stroke-width="2"/>
       ${dots}
     </svg>`);
  return wrap;
}

function drawGauge(score) {
  const r = 46, c = 2 * Math.PI * r, off = c * (1 - score / 100);
  document.getElementById("gauge").innerHTML =
    `<svg width="108" height="108" viewBox="0 0 108 108">
      <circle cx="54" cy="54" r="${r}" fill="none" stroke="var(--panel-2)" stroke-width="10"/>
      <circle cx="54" cy="54" r="${r}" fill="none" stroke="${scoreColor(score)}" stroke-width="10"
        stroke-linecap="round" stroke-dasharray="${c}" stroke-dashoffset="${off}"/>
    </svg>
    <div class="val"><b>${score}</b><span>/ 100</span></div>`;
}

function architecture(rep) {
  const layers = new Set((rep.graph.nodes || []).map(n => n.layer));
  const hasInject = (rep.graph.edges || []).some(e => e.kind === "injects");
  const missRepo = rep.violations.some(v => v.type === "missing_repository");
  const ctrlApi = rep.violations.some(v => v.type === "controller_to_api");
  const b = (ok, label) => `<span class="badge ${ok?"g":"b"}">${label}</span>`;
  const wrap = el("div", "badges");
  wrap.innerHTML =
    b(!ctrlApi, "Clean flow") +
    b(!missRepo && layers.has("repository"), "Repository") +
    b(layers.has("usecase"), "UseCases") +
    b(hasInject, "Dependency injection");
  return wrap;
}

function coverage(rep) {
  const cov = rep.coverage;
  if (!cov) return el("p", "empty", "Run <code>relax quality --coverage</code> to measure coverage.");
  const wrap = el("div");
  wrap.appendChild(el("div", "cov-row",
    `<span class="lbl">Overall</span>
     <span class="bar"><i style="width:${cov.overall}%;background:${covColor(cov.overall)}"></i></span>
     <span class="pct">${cov.overall}%</span>`));
  LAYERS.filter(l => cov.byLayer[l] != null).forEach(l => {
    const p = cov.byLayer[l];
    wrap.appendChild(el("div", "cov-row",
      `<span class="lbl">${l}</span>
       <span class="bar"><i style="width:${p}%;background:${covColor(p)}"></i></span>
       <span class="pct">${p}%</span>`));
  });
  return wrap;
}

function tests(rep) {
  const t = rep.testRun;
  if (!t) return el("p", "empty", "Run <code>relax quality --test</code> to run the suite.");
  const wrap = el("div");
  wrap.appendChild(el("div", "stat",
    `<div><b>${t.total}</b><span>total</span></div>
     <div><b style="color:var(--good)">${t.passed}</b><span>passed</span></div>
     <div><b style="color:${t.failed?"var(--bad)":"var(--muted)"}">${t.failed}</b><span>failed</span></div>
     <div><b>${t.skipped}</b><span>skipped</span></div>
     <div><b>${(t.durationMs/1000).toFixed(1)}s</b><span>time</span></div>`));
  if (t.failures && t.failures.length) {
    const ul = el("ul", "list");
    t.failures.forEach(f => ul.appendChild(el("li", null,
      `<span class="sev b">FAIL</span> ${esc(f.testName)}<br><code>${esc((f.message||"").split("\n")[0])}</code>`)));
    wrap.appendChild(el("div", null, "")).appendChild(ul);
  }
  return wrap;
}

function violations(rep) {
  if (!rep.violations.length) return el("p", "empty", "No architecture violations. 🎉");
  const wrap = el("div");
  rep.violations.forEach(v => {
    const cls = v.severity === "error" ? "b" : v.severity === "warning" ? "w" : "i";
    wrap.appendChild(el("div", "row",
      `<span><span class="sev ${cls}">${v.type}</span> ${esc(v.message)}</span>
       <span class="muted">${v.occurrences}×</span>`));
  });
  return wrap;
}

function issues(rep) {
  if (!rep.issues.length) return el("p", "empty", "No quality issues.");
  const wrap = el("div");
  rep.issues.slice(0, 30).forEach(i => {
    const cls = i.severity === "error" ? "b" : i.severity === "warning" ? "w" : "i";
    wrap.appendChild(el("div", "row",
      `<span><span class="sev ${cls}">${i.rule}</span> ${esc(i.message)}</span>
       <span class="muted">${esc(i.filePath.split("/").pop())}:${i.line}</span>`));
  });
  return wrap;
}

function gaps(rep) {
  if (!rep.testGaps.length) return el("p", "empty", "Every business function has a test. 🎉");
  const wrap = el("div");
  rep.testGaps.forEach(g => wrap.appendChild(el("div", "row",
    `<span>${esc(g.function)}()</span><span class="muted">${esc(g.expectedTestFile)}</span>`)));
  return wrap;
}

function heatmap(rep) {
  const src = (rep.coverage && rep.coverage.byFeature) || rep.heatmap || {};
  const keys = Object.keys(src);
  if (!keys.length) return null;
  const grid = el("div", "heat");
  keys.sort((a, b) => src[a] - src[b]).forEach(k => {
    const p = src[k];
    const cell = el("div", "cell", `<b>${p}%</b><span>${esc(k)}</span>`);
    cell.style.background = covColor(p);
    grid.appendChild(cell);
  });
  return grid;
}

function graph(rep) {
  const nodes = rep.graph.nodes || [], edges = rep.graph.edges || [];
  if (!nodes.length) return el("p", "empty", "No classes to graph.");
  const cols = LAYERS.filter(l => nodes.some(n => n.layer === l));
  const colX = {}, colW = 190, gap = 40, rowH = 34, boxW = 150, boxH = 24, pad = 24;
  cols.forEach((l, i) => colX[l] = pad + i * (colW + gap));
  const byLayer = {}; cols.forEach(l => byLayer[l] = []);
  nodes.forEach(n => (byLayer[n.layer] = byLayer[n.layer] || []).push(n));
  const pos = {}; let maxRows = 0;
  cols.forEach(l => { byLayer[l].forEach((n, r) => pos[n.id] = { x: colX[l], y: 46 + r * rowH }); maxRows = Math.max(maxRows, byLayer[l].length); });
  const width = pad * 2 + cols.length * colW + (cols.length - 1) * gap;
  const height = 46 + Math.max(1, maxRows) * rowH + pad;

  let svg = `<svg viewBox="0 0 ${width} ${height}" preserveAspectRatio="xMinYMin meet">`;
  cols.forEach(l => svg += `<text class="col-label" x="${colX[l]}" y="28">${l}</text>`);
  edges.forEach((e, i) => {
    const a = pos[e.from], b = pos[e.to]; if (!a || !b) return;
    const x1 = a.x + boxW, y1 = a.y + boxH/2, x2 = b.x, y2 = b.y + boxH/2;
    const mx = (x1 + x2) / 2;
    svg += `<path class="edge" data-from="${e.from}" data-to="${e.to}" d="M${x1},${y1} C${mx},${y1} ${mx},${y2} ${x2},${y2}"/>`;
  });
  nodes.forEach(n => {
    const p = pos[n.id]; if (!p) return;
    svg += `<g class="node" data-id="${esc(n.id)}" transform="translate(${p.x},${p.y})">
      <rect width="${boxW}" height="${boxH}"/>
      <text x="8" y="16">${esc(n.label.length > 20 ? n.label.slice(0,19)+"…" : n.label)}</text></g>`;
  });
  svg += `</svg>`;
  const wrap = el("div", null, svg); wrap.id = "graph";
  wrap.addEventListener("click", ev => {
    const g = ev.target.closest(".node");
    wrap.querySelectorAll(".edge").forEach(e => e.classList.remove("hot"));
    wrap.querySelectorAll(".node").forEach(n => n.classList.remove("dim"));
    if (!g) return;
    const id = g.getAttribute("data-id");
    const connected = new Set([id]);
    wrap.querySelectorAll(".edge").forEach(e => {
      if (e.dataset.from === id || e.dataset.to === id) {
        e.classList.add("hot"); connected.add(e.dataset.from); connected.add(e.dataset.to);
      }
    });
    wrap.querySelectorAll(".node").forEach(n => { if (!connected.has(n.dataset.id)) n.classList.add("dim"); });
  });
  return wrap;
}
</script>
</body>
</html>''';
