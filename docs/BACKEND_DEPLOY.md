# Backend: Vultr + Tiger Data + Gemini + ElevenLabs

The game talks to one Python FastAPI app (`backend/`) running on a Vultr server at `https://64-177-50-25.sslip.io`. It keeps every API key off the game and does these jobs:

| Endpoint | What it does |
| --- | --- |
| `POST /reflection` | Gemini writes Barb the Sleep Sheep's morning report |
| `POST /notifications` | Gemini writes the phone notifications that haunt a scrolling player's dream |
| `POST /nights` | Saves each night to Tiger Data (needs the game key); returns community stats and today's rank |
| `GET /stats`, `GET /leaderboard` | Numbers for the stats page |
| `GET /barb/latest`, `GET /barb/voice` | The latest morning report, and ElevenLabs reading it aloud (cached per report) |
| `GET /dashboard` | The Live Sleep Stats page |
| `GET /health` | Shows which services are connected |

Every service is optional. If the backend is slow (over 4 seconds) or down, the game uses scripted text and skips the stats, so a night never breaks.

## Data (Tiger Data / TimescaleDB)
`schema.sql` creates the `nights` hypertable (one row per night: choices, the full evening routine as JSON, score, grade, sheep, country code, device type) and the `nights_hourly` continuous aggregate that refreshes every 5 minutes. Roblox user ids are stored only as salted SHA-256 hashes. The schema, including new columns, is applied automatically when the backend starts.

## How our server is set up
| What | Where |
| --- | --- |
| Server | Vultr Cloud Compute, Ubuntu 24.04, `root@64.177.50.25` |
| App files and `.env` | `/opt/snooze/` |
| Service | `snooze` (systemd, uvicorn on `127.0.0.1:8000`, restarts on crash and reboot) |
| HTTPS | Caddy, `64-177-50-25.sslip.io` → `127.0.0.1:8000`, certificate automatic |
| Database | Tiger Cloud service (connection string in `.env`) |

## Updating the server
After pulling new backend code, from the `backend/` folder on your laptop:
```bash
scp main.py db.py voice.py schema.sql dashboard.html root@64.177.50.25:/opt/snooze/
ssh root@64.177.50.25 "systemctl restart snooze"
curl https://64-177-50-25.sslip.io/health
```
`/health` should show `"database": true`, `"gemini": true`, and `"elevenlabs": true`. To see errors: `ssh root@64.177.50.25 "journalctl -u snooze -n 50 --no-pager"`.

## Setting it up from scratch
1. **Tiger Data:** create a free service at Tiger Cloud, open **Connect**, and copy the connection string (`postgres://tsdbadmin:...?sslmode=require`).
2. **Vultr:** deploy Ubuntu 24.04 (smallest plan), then on the server:
   ```bash
   apt update && apt install -y python3-venv caddy
   mkdir -p /opt/snooze
   ```
3. **Copy the backend** from your laptop's `backend/` folder:
   ```bash
   scp -r *.py *.sql requirements.txt dashboard.html static .env.example root@SERVER_IP:/opt/snooze/
   ```
4. **Install and configure** on the server:
   ```bash
   cd /opt/snooze && python3 -m venv venv && venv/bin/pip install -r requirements.txt
   cp .env.example .env && nano .env   # GEMINI_API_KEY, ELEVENLABS_API_KEY, DATABASE_URL, GAME_API_KEY, PLAYER_SALT
   ```
   Make sure `.env` ends with a newline before appending keys with `echo >>`, or two keys end up on one line.
5. **Run it as a service:**
   ```bash
   cat > /etc/systemd/system/snooze.service <<'UNIT'
   [Unit]
   Description=Snooze You Choose backend
   After=network.target
   [Service]
   WorkingDirectory=/opt/snooze
   ExecStart=/opt/snooze/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
   Restart=always
   [Install]
   WantedBy=multi-user.target
   UNIT
   systemctl enable --now snooze
   ```
6. **HTTPS:** `sslip.io` turns the IP into a hostname (dots become dashes) and Caddy gets the certificate:
   ```bash
   echo 'SERVER-IP-WITH-DASHES.sslip.io {
       reverse_proxy 127.0.0.1:8000
   }' > /etc/caddy/Caddyfile
   systemctl restart caddy
   ```
   If the Vultr firewall is on, allow ports 80 and 443.

## Connecting the game
Copy `src/server/BackendConfig.example.luau` to `src/server/BackendConfig.luau` and fill it in:
```lua
return {
	url = "https://64-177-50-25.sslip.io",
	gameKey = "same value as GAME_API_KEY",
}
```
This file is ignored by git, so the key never gets committed; share it with teammates privately. Rojo syncs it into Studio. HTTP requests are enabled through `default.project.json` (also check **Game Settings → Security → Allow HTTP Requests** for the published game).

## Barb's voice (ElevenLabs)
- The stats page's **Hear Barb** button uses the server's `ELEVENLABS_API_KEY` (the key needs Text to Speech access).
- The five in-game grade lines were made once on a laptop with `venv/bin/python make_barb_lines.py`, uploaded to Roblox, and their ids are in `src/shared/BarbVoice.luau`. Roblox only plays them in experiences owned by the uploader (or ones given permission in Creator Hub).

## Testing backend changes on your laptop
```bash
cd backend && python3 -m venv venv && venv/bin/pip install -r requirements.txt
cp .env.example .env              # fill in; DATABASE_URL can be any Postgres, or left empty
venv/bin/python check_setup.py    # checks each connection and says how to fix what isn't working
venv/bin/uvicorn main:app --reload   # then open http://localhost:8000/dashboard
```
The game itself always talks to the Vultr server; deploy with **Updating the server** above when your change works.
