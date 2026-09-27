# Backend: Tiger Data + Gemini + Vultr

The FastAPI backend (`backend/`) does three jobs:

| Endpoint | What it does |
| --- | --- |
| `POST /notifications` | Gemini writes the phone notifications that haunt a scrolling player's dream |
| `POST /reflection` | Gemini writes Barb the Sleep Sheep's morning report |
| `POST /nights` | Saves each night to **Tiger Data**; returns community stats and today's rank for the morning screen |
| `GET /stats`, `GET /leaderboard` | Aggregates for the dashboard |
| `GET /dashboard` | **Live web dashboard** for judges: habit rates, grades, stability by phone choice, hourly trend, leaderboard |
| `GET /health` | Shows which features are connected |

Every feature is optional. The game falls back to scripted text and skips stats whenever the backend is unavailable, so the demo never breaks.

## Data model (Tiger Data / TimescaleDB)
`schema.sql` creates a `nights` **hypertable** (one row per night: choices, stability, grade, sheep, stumbles, seconds left) and a `nights_hourly` **continuous aggregate** that refreshes every 5 minutes and powers the dashboard's hourly chart. Roblox user ids are stored only as salted SHA-256 hashes. The schema is applied automatically at startup. On plain PostgreSQL, the Timescale-only parts are skipped.

## 1. Tiger Data (about 5 minutes)
1. Sign up at Tiger Data (tigerdata.com, "Tiger Cloud") and create a free service.
2. Open the service → **Connect** → copy the connection string (`postgres://tsdbadmin:...?sslmode=require`).
3. That string is your `DATABASE_URL`.

## 2. Vultr server (about 20 minutes)
1. Claim the MLH Vultr credits, then **Deploy → Cloud Compute → Ubuntu 24.04**, smallest plan.
2. SSH in: `ssh root@YOUR_SERVER_IP`
3. Install and download the code:
   ```bash
   apt update && apt install -y python3-venv git caddy
   git clone https://github.com/ysalbador24/Tigerhacks-.git /opt/snooze
   cd /opt/snooze && git checkout claude/roblox-game-design-ss3x82
   cd backend && python3 -m venv venv && venv/bin/pip install -r requirements.txt
   cp .env.example .env && nano .env   # fill in GEMINI_API_KEY, DATABASE_URL, GAME_API_KEY, PLAYER_SALT
   ```
4. Run it as a service, so it survives SSH logouts and reboots:
   ```bash
   cat > /etc/systemd/system/snooze.service <<'UNIT'
   [Unit]
   Description=Snooze You Choose backend
   After=network.target
   [Service]
   WorkingDirectory=/opt/snooze/backend
   ExecStart=/opt/snooze/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
   Restart=always
   [Install]
   WantedBy=multi-user.target
   UNIT
   systemctl enable --now snooze
   ```
5. HTTPS with Caddy. `sslip.io` gives your IP a free hostname, and Caddy gets the certificate automatically. Replace the dots in your IP with dashes:
   ```bash
   echo 'YOUR-IP-WITH-DASHES.sslip.io {
       reverse_proxy 127.0.0.1:8000
   }' > /etc/caddy/Caddyfile
   systemctl restart caddy
   ```
6. If your Vultr firewall is on, allow ports 80 and 443.
7. Check `https://YOUR-IP-WITH-DASHES.sslip.io/health`. It should show `"database": true, "gemini": true`.

## 3. Connect the game
Copy `src/server/BackendConfig.example.luau` to `src/server/BackendConfig.luau` and fill it in:
```lua
return {
	url = "https://YOUR-IP-WITH-DASHES.sslip.io",
	gameKey = "same value as GAME_API_KEY",
}
```
`BackendConfig.luau` is ignored by git, so the URL and key never get committed. Rojo still syncs it into Studio. HTTP requests are enabled through `default.project.json`.

## Barb's voice (ElevenLabs, optional)
1. Add `ELEVENLABS_API_KEY=...` to `.env` on your laptop and on the server (`/opt/snooze/.env`), then `systemctl restart snooze`. `/health` shows `"elevenlabs": true`.
2. Dashboard: the "🔊 Hear Barb" button reads the latest morning report out loud (`GET /barb/voice`, cached per report).
3. In-game grade lines: on your laptop run `venv/bin/python make_barb_lines.py`. Upload the 5 mp3s in `barb_lines/` to Roblox (Creator Hub → Development Items → Audio, or Studio → Asset Manager → Bulk Import), then paste each id into `src/shared/BarbVoice.luau` as `"rbxassetid://123..."`.

If ElevenLabs refuses requests from the server's IP (free-tier abuse filters sometimes do this), the in-game lines still work because they're recorded once from your laptop.

## 4. Demo
Open `https://YOUR-IP-WITH-DASHES.sslip.io/dashboard` on a laptop next to the game. Every night a judge plays shows up within 5 seconds.

## Local development
```bash
cd backend && python3 -m venv venv && venv/bin/pip install -r requirements.txt
cp .env.example .env        # fill in; the database URL can point at any Postgres, or leave it empty
venv/bin/python check_setup.py   # tells you what's connected and how to fix what isn't
venv/bin/uvicorn main:app --reload
```
Roblox can't reach `localhost`, so use `ngrok http 8000` and put the ngrok URL in `BackendConfig.luau`.
