// The fleet's status page. Nodes push heartbeats signed with their SSH host
// key (ssh-keygen -Y sign); this checks each against the host key in
// hosts.nix, so nothing on either side holds a secret. A cron probes every
// node's P2P port from outside, which a node cannot vouch for itself.
import { connect } from "cloudflare:sockets";
import hosts from "./hosts.json";
import land from "./land.json";

const NAMESPACE = "fleet-heartbeat";
const MAX_SKEW = 300; // seconds a heartbeat may be old, so one cannot be replayed later
const STALE = 180; // seconds without a heartbeat before a node counts as silent

const enc = new TextEncoder();
const b64 = (s) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
const u32 = (n) => new Uint8Array([n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255]);
const cat = (...parts) => {
  const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  parts.reduce((off, p) => (out.set(p, off), off + p.length), 0);
  return out;
};
const sshString = (bytes) => cat(u32(bytes.length), bytes);
const eq = (a, b) => a.length === b.length && a.every((x, i) => x === b[i]);

// SSHSIG (openssh PROTOCOL.sshsig): MAGIC, version, then five strings.
function parseSig(armored) {
  const blob = b64(armored.replace(/-----[^-]+-----/g, "").replace(/\s/g, ""));
  const view = new DataView(blob.buffer);
  let off = 10; // "SSHSIG" + uint32 version
  const next = () => {
    const len = view.getUint32(off);
    const s = blob.subarray(off + 4, off + 4 + len);
    off += 4 + len;
    return s;
  };
  if (new TextDecoder().decode(blob.subarray(0, 6)) !== "SSHSIG") throw new Error("not an SSHSIG");
  const [publicKey, namespace, reserved, hashAlg, signature] = [next(), next(), next(), next(), next()];
  return { publicKey, namespace, reserved, hashAlg, signature };
}

async function verify(host, body, armored) {
  const sig = parseSig(armored);
  const dec = new TextDecoder();
  if (!eq(sig.publicKey, b64(host.hostKey.split(" ")[1]))) throw new Error("not this host's key");
  if (dec.decode(sig.namespace) !== NAMESPACE) throw new Error("wrong namespace");
  const alg = dec.decode(sig.hashAlg);
  const digest = new Uint8Array(await crypto.subtle.digest(alg === "sha256" ? "SHA-256" : "SHA-512", enc.encode(body)));
  const signed = cat(enc.encode("SSHSIG"), sshString(sig.namespace), sshString(sig.reserved), sshString(sig.hashAlg), sshString(digest));
  // The signature string is itself string("ssh-ed25519") + string(64 bytes).
  const raw = sig.signature.subarray(sig.signature.length - 64);
  const key = await crypto.subtle.importKey("raw", sig.publicKey.subarray(sig.publicKey.length - 32), { name: "Ed25519" }, false, ["verify"]);
  if (!(await crypto.subtle.verify("Ed25519", key, raw, signed))) throw new Error("bad signature");
}

async function beat(request, env) {
  const { body, sig } = await request.json();
  const data = JSON.parse(body);
  const host = hosts[data.host];
  if (!host) return new Response("unknown host", { status: 403 });
  try {
    await verify(host, body, sig);
  } catch (e) {
    return new Response(e.message, { status: 403 });
  }
  if (Math.abs(Date.now() / 1000 - data.time) > MAX_SKEW) return new Response("stale", { status: 403 });
  await env.FLEET.put(`beat:${data.host}`, body);
  return new Response("ok");
}

async function probe(ip, port) {
  const socket = connect({ hostname: ip, port });
  const timeout = new Promise((_, reject) => setTimeout(() => reject(new Error("timeout")), 5000));
  try {
    await Promise.race([socket.opened, timeout]);
    return true;
  } catch {
    return false;
  } finally {
    socket.close().catch(() => {});
  }
}

async function status(env) {
  const now = Date.now() / 1000;
  const rows = await Promise.all(
    Object.entries(hosts).map(async ([name, h]) => {
      const beat = JSON.parse((await env.FLEET.get(`beat:${name}`)) || "null");
      const p2p = JSON.parse((await env.FLEET.get(`probe:${name}`)) || "null");
      return { name, ...h, beat, p2p, age: beat ? Math.round(now - beat.time) : null };
    }),
  );
  const tip = Math.max(0, ...rows.map((r) => r.beat?.height ?? 0));
  for (const r of rows) {
    r.lag = r.beat?.height != null ? tip - r.beat.height : null;
    r.state = !r.beat || r.age > STALE ? "down" : r.beat.restoring ? "restoring" : r.beat.ready && r.p2p?.open ? "ok" : "degraded";
  }
  return { tip, rows };
}

const esc = (v) => String(v ?? "—").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
const ago = (s) => (s == null ? "never" : s < 120 ? `${s}s ago` : s < 7200 ? `${Math.round(s / 60)}m ago` : `${Math.round(s / 3600)}h ago`);
const num = (n) => (n == null ? "—" : n.toLocaleString("en-US"));

// land.json: Natural Earth 110m land as run-length rows of a 2-degree grid,
// alternating sea and land cells from longitude -180, rows from 80°N down.
// One dot per land cell, drawn once when the worker starts.
const COLS = 360 / land.step;
const dots = land.rows
  .flatMap((row, y) => {
    let x = 0;
    return row.split(",").flatMap((run, i) => {
      const cells = i % 2 ? Array.from({ length: +run }, (_, k) => `M${x + k + 0.5} ${y + 0.5}h0`) : [];
      x += +run;
      return cells;
    });
  })
  .join("");
const at = ([lat, lon]) => [(lon + 180) / land.step, (land.top - lat) / land.step + 0.5];

function map(rows) {
  const pins = rows
    .map((r) => {
      const [x, y] = at(r.coordinates);
      return `<g class="pin ${r.state}"><circle class="ring" cx="${x}" cy="${y}" r="1.2"/><circle cx="${x}" cy="${y}" r="0.9"/>
<text x="${x + 1.8}" y="${y + 0.6}">${esc(r.name)}</text></g>`;
    })
    .join("");
  return `<svg viewBox="0 0 ${COLS} ${land.rows.length}" role="img" aria-label="Map of node locations">
<path class="land" d="${dots}"/>${pins}</svg>`;
}

function page({ tip, rows }) {
  const healthy = rows.filter((r) => r.state === "ok").length;
  const versions = [...new Set(rows.map((r) => r.beat?.version).filter(Boolean))].join(", ") || "—";
  const tr = rows
    .map(
      (r) => `<tr class="${r.state}"><td><b>${esc(r.name)}</b><small>${esc(r.location)} · ${esc(r.storage)}</small></td>
<td><span class="dot"></span>${esc(r.state)}</td><td class="n">${num(r.beat?.height)}</td><td class="n">${esc(r.lag)}</td>
<td class="n">${esc(r.beat?.peers)}</td><td>${r.p2p ? (r.p2p.open ? "open" : "closed") : "—"}</td>
<td>${esc(r.beat?.version)}</td><td class="n">${esc(r.beat?.disk)}</td><td>${esc(ago(r.age))}</td></tr>`,
    )
    .join("");
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="30"><title>Cypherpunk Infra</title><link rel="icon" href="/mark.svg" type="image/svg+xml"><style>
@font-face{font-family:"New Science";src:url(/fonts/new-science-bold.woff2) format("woff2");font-weight:700;font-display:swap}
@font-face{font-family:"Fira Mono";src:url(/fonts/fira-mono.woff2) format("woff2");font-display:swap}
:root{--black:#000;--white:#fff;--neon:#0ce700;--dark:#000500;--deep:#011700;--line:#0ce70066;--mut:#8a8a8a;--bad:#ff4d4d}
*{box-sizing:border-box}
body{margin:0;background:var(--black) radial-gradient(#1c1c1c 1px,transparent 1px) 0 0/24px 24px;color:var(--white);
font:14px/1.6 "Fira Mono",ui-monospace,monospace;text-transform:uppercase;letter-spacing:.06em}
main{max-width:1200px;margin:0 auto;padding:24px 16px 64px}
header{display:flex;align-items:center;justify-content:space-between;gap:16px;border:1px solid var(--neon);padding:20px 24px}
header img{height:18px;display:block}.nav{display:flex;color:var(--neon);text-decoration:none;white-space:nowrap}.nav:hover{text-decoration:underline}.gh{color:var(--white)}.gh:hover{color:var(--neon)}
.kicker{display:flex;align-items:center;gap:16px;color:var(--neon);margin:56px 0 8px}
.kicker svg{width:min(360px,50vw);height:24px}
h1{font:700 clamp(40px,8vw,88px)/1 "New Science","Arial Black",sans-serif;letter-spacing:-.01em;margin:0 0 40px}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));border:1px solid var(--line)}
.stats div{padding:16px 20px;border-right:1px solid var(--line)}.stats div:last-child{border-right:0}
.stats small{display:block;color:var(--mut);font-size:11px;letter-spacing:.14em}.stats b{color:var(--neon);font-weight:400;font-size:16px}
.map{margin:32px 0;border:1px solid var(--line);background:var(--dark);padding:16px}
.map svg{width:100%;display:block}
.land{stroke:#1f4d1f;stroke-width:.5;stroke-linecap:round}
.pin circle{fill:var(--neon)}.pin text{fill:var(--neon);font-size:1.5px;letter-spacing:.05em}
.pin .ring{fill:none;stroke:var(--neon);stroke-width:.2;animation:pulse 2s ease-out infinite;transform-box:fill-box;transform-origin:center}
.pin.down circle{fill:var(--bad)}.pin.down .ring{stroke:var(--bad)}.pin.down text{fill:var(--bad)}
.pin.restoring circle,.pin.degraded circle{fill:var(--white)}.pin.restoring .ring,.pin.degraded .ring{stroke:var(--white)}.pin.restoring text,.pin.degraded text{fill:var(--white)}
@keyframes pulse{from{transform:scale(1);opacity:1}to{transform:scale(3);opacity:0}}
@media (prefers-reduced-motion:reduce){.pin .ring{animation:none}}
.wrap{overflow-x:auto;border:1px solid var(--line)}
table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:14px 16px;border-bottom:1px solid #0ce70026;white-space:nowrap}
tr:last-child td{border-bottom:0}th{color:var(--mut);font-weight:400;font-size:11px;letter-spacing:.14em}
td small{display:block;color:var(--mut);font-size:11px}td b{font-weight:400;color:var(--neon)}.n{text-align:right;font-variant-numeric:tabular-nums}
.dot{display:inline-block;width:8px;height:8px;margin-right:8px;background:var(--neon)}
.down .dot{background:var(--bad)}.restoring .dot,.degraded .dot{background:var(--white)}
.note{color:var(--mut);margin:0 0 12px}
pre{margin:0;padding:16px 20px;border:1px solid var(--line);background:var(--dark);color:var(--neon);text-transform:none;overflow-x:auto;user-select:all}
footer{display:flex;align-items:center;justify-content:space-between;color:var(--mut);font-size:11px;letter-spacing:.14em;margin-top:24px}
</style></head><body><main>
<header><a href="https://cypherpunk.com"><img src="/wordmark.svg" alt="./cypherpunk"></a><a class="nav" href="https://cypherpunk.com">cypherpunk.com ↗</a></header>
<div class="kicker">// Zakura nodes<svg viewBox="0 0 360 24" aria-hidden="true"><path d="M0 4H280L340 20" fill="none" stroke="#0ce700"/><rect x="336" y="16" width="8" height="8" fill="#0ce700"/></svg></div>
<h1>Cypherpunk infra</h1>
<div class="stats"><div><small>Nodes healthy</small><b>${healthy}/${rows.length}</b></div><div><small>Fleet tip</small><b>#${num(tip)}</b></div>
<div><small>Client</small><b>${esc(versions)}</b></div><div><small>P2P</small><b>v1 + v2</b></div></div>
<div class="map">${map(rows)}</div>
<div class="wrap"><table><tr><th>Node</th><th>State</th><th class="n">Height</th><th class="n">Lag</th><th class="n">Peers</th><th>P2P port</th><th>Version</th><th class="n">Disk</th><th>Heartbeat</th></tr>${tr}</table></div>
<div class="kicker">// Peer with us<svg viewBox="0 0 360 24" aria-hidden="true"><path d="M0 4H280L340 20" fill="none" stroke="#0ce700"/><rect x="336" y="16" width="8" height="8" fill="#0ce700"/></svg></div>
<p class="note">Add our Zakura node cluster to your node's peers:</p>
<pre>${esc(rows.flatMap((r) => [`${r.ipv4}:8233`, ...(r.ipv6 ? [`[${r.ipv6}]:8233`] : [])]).join("\n"))}</pre>
<footer><span>Refreshes every 30s</span><a class="nav gh" href="https://github.com/cypherpunktech/node-infrastructure" aria-label="Source on GitHub"><svg viewBox="0 0 16 16" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg></a></footer>
</main></body></html>`;
}

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (request.method === "POST" && pathname === "/beat") return beat(request, env);
    if (pathname === "/api") return Response.json(await status(env));
    if (pathname === "/") return new Response(page(await status(env)), { headers: { "content-type": "text/html; charset=utf-8" } });
    return new Response("not found", { status: 404 });
  },
  async scheduled(_event, env) {
    await Promise.all(
      Object.entries(hosts).map(async ([name, h]) =>
        env.FLEET.put(`probe:${name}`, JSON.stringify({ open: await probe(h.ipv4, 8233), time: Math.round(Date.now() / 1000) })),
      ),
    );
  },
};
