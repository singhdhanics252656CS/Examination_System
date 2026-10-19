const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'submissions.json');

const app = express();
app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(express.json({ limit: '50kb', type: () => true })); // parse JSON whatever the Content-Type header says
app.use((req, res, next) => {
  res.set({
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'strict-origin-when-cross-origin'
  });
  next();
});

/* ---------- storage (encrypted JSON file, written atomically) ---------- */
// AES-256-GCM encryption. Set ENCRYPTION_KEY in Render (any long random text).
// WARNING: if you lose or change this key, existing submissions cannot be read again.
fs.mkdirSync(DATA_DIR, { recursive: true });
const KEY = process.env.ENCRYPTION_KEY ? crypto.scryptSync(process.env.ENCRYPTION_KEY, 'cybersafe-india-salt', 32) : null;
if (!KEY) console.warn('WARNING: ENCRYPTION_KEY is not set. Submissions are stored UNENCRYPTED.');
const PREFIX = 'enc:v1:';

function encrypt(text) {
  const iv = crypto.randomBytes(12);
  const c = crypto.createCipheriv('aes-256-gcm', KEY, iv);
  const data = Buffer.concat([c.update(text, 'utf8'), c.final()]);
  return PREFIX + Buffer.concat([iv, c.getAuthTag(), data]).toString('base64');
}
function decrypt(text) {
  const buf = Buffer.from(text.slice(PREFIX.length), 'base64');
  const d = crypto.createDecipheriv('aes-256-gcm', KEY, buf.subarray(0, 12));
  d.setAuthTag(buf.subarray(12, 28));
  return Buffer.concat([d.update(buf.subarray(28)), d.final()]).toString('utf8');
}

const toText = obj => { const j = JSON.stringify(obj); return KEY ? encrypt(j) : j; };
const fromText = t => (t.startsWith(PREFIX) ? JSON.parse(decrypt(t)) : JSON.parse(t));

/* Two storage options:
   1) DATABASE_URL set  -> PostgreSQL (permanent, visible from everywhere, survives redeploys)
   2) not set           -> local JSON file (lost when Render's free plan restarts) */
let store;
if (process.env.DATABASE_URL) {
  const { Pool } = require('pg');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false }, max: 5 });
  store = {
    name: 'PostgreSQL database',
    async init() {
      await pool.query('CREATE TABLE IF NOT EXISTS submissions (id SERIAL PRIMARY KEY, created TIMESTAMPTZ DEFAULT now(), data TEXT NOT NULL)');
    },
    async add(row) { await pool.query('INSERT INTO submissions (data) VALUES ($1)', [toText(row)]); },
    async list() {
      const r = await pool.query('SELECT data FROM submissions ORDER BY id');
      const out = [];
      for (const x of r.rows) { try { out.push(fromText(x.data)); } catch (e) { console.error('Skipping unreadable row'); } }
      return out;
    }
  };
} else {
  let subs = [];
  const save = () => { const tmp = DATA_FILE + '.tmp'; fs.writeFileSync(tmp, toText(subs)); fs.renameSync(tmp, DATA_FILE); };
  store = {
    name: 'local file (NOT permanent on the free plan)',
    async init() {
      try {
        const raw = fs.readFileSync(DATA_FILE, 'utf8').trim();
        if (raw) subs = fromText(raw);
      } catch (e) {
        if (e.code !== 'ENOENT') {
          console.error('Could not read saved submissions:', e.message);
          try { fs.copyFileSync(DATA_FILE, DATA_FILE + '.unreadable-' + Date.now()); } catch (x) {}
        }
        subs = [];
      }
    },
    async add(row) { subs.push(row); try { save(); } catch (e) { subs.pop(); throw e; } },
    async list() { return subs; }
  };
}

/* ---------- helpers ---------- */
const sha = s => crypto.createHash('sha256').update(String(s)).digest();
const same = (a, b) => crypto.timingSafeEqual(sha(a), sha(b));
const SECRET = () => process.env.SESSION_SECRET;
const sign = t => crypto.createHmac('sha256', SECRET()).update(t).digest('base64url');
const makeToken = () => { const e = String(Date.now() + 2 * 3600 * 1000); return e + '.' + sign(e); };
function validToken(t) {
  if (!t) return false;
  const [e, s] = t.split('.');
  if (!e || !s || Date.now() > Number(e)) return false;
  const x = Buffer.from(sign(e)), y = Buffer.from(s);
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

// Tiny in-memory rate limiter
const hits = new Map();
function limit(name, max, windowMs) {
  return (req, res, next) => {
    const key = name + ':' + req.ip, now = Date.now();
    const arr = (hits.get(key) || []).filter(t => now - t < windowMs);
    if (arr.length >= max) return res.status(429).json({ error: 'Too many attempts. Please wait a while and try again.' });
    arr.push(now); hits.set(key, arr); next();
  };
}
setInterval(() => { const now = Date.now(); for (const [k, v] of hits) if (!v.some(t => now - t < 3600e3)) hits.delete(k); }, 600e3).unref();

const AGES = ['Below 18', '18 to 30', '31 to 45', '46 to 59', '60 and above'];
const TYPES = ['UPI or payment fraud', 'Phishing link or fake website', 'Digital arrest or fake officer call', 'Sextortion or blackmail', 'Job or task fraud', 'Fake loan app', 'Harassment, stalking or morphing', 'Account hacked', 'Other'];
const REPORTED = ['Yes', 'No', 'Not sure'];
const clip = (v, n) => String(v == null ? '' : v).trim().slice(0, n);

/* ---------- public: save an experience ---------- */
app.post('/api/submit', limit('submit', 10, 3600e3), async (req, res) => {
  const b = req.body || {};
  if (b['bot-field']) return res.json({ ok: true }); // honeypot: pretend success
  const row = {
    at: new Date().toISOString(),
    name: clip(b.name, 100),
    age: clip(b.age_group, 20),
    city: clip(b.city, 100),
    type: clip(b.crime_type, 60),
    story: clip(b.story, 4000),
    reported: clip(b.reported, 10),
    email: clip(b.email, 150)
  };
  if (!AGES.includes(row.age) || !TYPES.includes(row.type) || !REPORTED.includes(row.reported) || !row.story)
    return res.status(400).json({ error: 'Please fill in all required fields.' });
  if (b.consent !== true && b.consent !== 'on') return res.status(400).json({ error: 'Please tick the consent box.' });
  if (row.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(row.email)) return res.status(400).json({ error: 'That email address does not look right.' });
  try { await store.add(row); } catch (e) { console.error(e); return res.status(500).json({ error: 'Could not save right now.' }); }
  res.json({ ok: true });
});

/* ---------- admin ---------- */
app.use('/api/admin', (req, res, next) => {
  res.set('Cache-Control', 'no-store');
  const miss = ['ADMIN_USER', 'ADMIN_PASS', 'SESSION_SECRET'].filter(k => !process.env[k]);
  if (miss.length) return res.status(500).json({ error: 'Server is not set up yet. Missing: ' + miss.join(', ') });
  next();
});

app.post('/api/admin', limit('login', 10, 15 * 60e3), async (req, res) => {
  const b = req.body || {};
  const good = same(String(b.user || '').trim().toLowerCase(), String(process.env.ADMIN_USER).trim().toLowerCase()) & same(String(b.pass || '').trim(), String(process.env.ADMIN_PASS).trim());
  if (!good) { await new Promise(r => setTimeout(r, 1000)); return res.status(401).json({ error: 'Wrong username or password' }); }
  res.json({ token: makeToken() });
});

app.get('/api/admin', async (req, res) => {
  if (!validToken((req.headers.authorization || '').replace(/^Bearer /, '')))
    return res.status(401).json({ error: 'Session expired. Please log in again.' });
  try { res.json({ rows: await store.list() }); } catch (e) { console.error(e); res.status(500).json({ error: 'Could not load submissions.' }); }
});

app.get('/healthz', (req, res) => res.send('ok'));

/* ---------- static site (only these 3 files are public) ---------- */
const send = f => (req, res) => res.sendFile(path.join(__dirname, f));
app.get('/', send('index.html'));
app.get('/index.html', send('index.html'));
app.get('/script.js', send('script.js'));
app.get('/style.css', send('style.css'));
app.use((req, res) => res.status(404).sendFile(path.join(__dirname, 'index.html')));

store.init().then(() => {
  app.listen(PORT, () => console.log('CyberSafe India running on port ' + PORT + '. Storage: ' + store.name));
}).catch(e => { console.error('Could not start storage:', e.message); process.exit(1); });
