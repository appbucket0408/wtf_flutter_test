// WTF Agora token server
// - GET  /token?userId=&role=&roomId= -> { token, appId, uid } (RTC token for joining channel roomId)
// - POST /room { name }               -> { roomId } (Agora channels are created on join; echoes name)
// - GET  /health                      -> { ok: true }
require('dotenv').config();
const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

const { AGORA_APP_ID, AGORA_APP_CERTIFICATE, PORT = 3000 } = process.env;

if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
  console.error('[token_server] Missing AGORA_APP_ID / AGORA_APP_CERTIFICATE in .env');
  process.exit(1);
}

// Fixed numeric uids per seeded persona (Agora joins with int uids).
const UIDS = { member_dk: 1, trainer_aarav: 2 };
const TOKEN_TTL_SEC = 24 * 60 * 60;

const app = express();
app.use(express.json());

app.get('/token', (req, res) => {
  const { userId, role, roomId } = req.query;
  if (!userId || !role || !roomId) {
    return res.status(400).json({ error: 'userId, role and roomId are required' });
  }
  const uid = UIDS[userId] ?? 0;
  const now = Math.floor(Date.now() / 1000);
  const token = RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID,
    AGORA_APP_CERTIFICATE,
    roomId,               // channel name
    uid,
    RtcRole.PUBLISHER,    // both member and trainer publish audio+video
    now + TOKEN_TTL_SEC,  // token expiry
    now + TOKEN_TTL_SEC,  // privilege expiry
  );
  console.log(`[token] user=${userId} uid=${uid} role=${role} channel=${roomId}`);
  res.json({ token, appId: AGORA_APP_ID, uid });
});

// Agora has no room-creation REST requirement — a channel exists the moment
// someone joins it. Kept for API symmetry; idempotent by definition.
app.post('/room', (req, res) => {
  const { name } = req.body || {};
  if (!name) return res.status(400).json({ error: 'name is required' });
  console.log(`[room] channel=${name}`);
  res.json({ roomId: name });
});

app.get('/health', (_req, res) => res.json({ ok: true }));

app.listen(PORT, '0.0.0.0', () =>
  console.log(`[token_server] listening on http://0.0.0.0:${PORT}`),
);
