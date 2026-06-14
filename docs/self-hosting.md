# Self-Hosting litflow (Windows + WSL2 + Cloudflare Tunnel)

Deployment runbook for hosting litflow on a Windows machine behind a home/office
router, using Kamal with a local container registry and Cloudflare Tunnel for
public access. No static IP, port forwarding, or DDNS is required.

## Architecture

```
Internet (users, HTTPS)
      │
   Cloudflare edge           TLS terminated here; origin IP hidden
      │ (outbound-only encrypted tunnel — no inbound ports)
      ▼
Windows machine
      └─ cloudflared (Windows service)   dials out to Cloudflare → localhost:80
               │ (WSL2 localhost forwarding)
               ▼
         WSL2 (Ubuntu, systemd)
            ├─ registry:2     local image registry on localhost:5000
            ├─ kamal-proxy:80 routes by host to the app container
            └─ litflow        Thruster → Puma, SQLite on a persistent volume
```

The Windows machine acts as both the build host and the server. Kamal builds the
image, pushes it to the local registry, and deploys to `127.0.0.1`.

`cloudflared` runs as a **Windows service** and reaches the app through WSL2's
localhost forwarding (`localhost:80` on Windows → kamal-proxy inside WSL2).
Running it inside WSL2 instead is also supported — see Phase 6.

## Prerequisites

- Windows 10/11 with administrator access.
- A domain managed in Cloudflare (DNS hosted on Cloudflare nameservers).
- The litflow repository and its `config/master.key`.

---

## Phase 1 — WSL2 with systemd

Run in **Windows PowerShell (Administrator)**:

```powershell
wsl --install
```

Reboot if prompted, launch **Ubuntu**, and create your Linux user. Then enable
systemd inside Ubuntu:

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

Restart the distribution from PowerShell:

```powershell
wsl --shutdown
```

Relaunch Ubuntu and confirm: `systemctl is-system-running` (`running` or
`degraded` is acceptable).

---

## Phase 2 — Docker and SSH inside WSL2

```bash
# Docker Engine
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl enable --now docker

# SSH server — Kamal connects to 127.0.0.1
sudo apt-get install -y openssh-server
sudo systemctl enable --now ssh

# Passwordless key for Kamal → localhost
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Close and reopen Ubuntu so the `docker` group applies, then verify:

```bash
docker run --rm hello-world
ssh -o StrictHostKeyChecking=accept-new 127.0.0.1 echo ok
```

---

## Phase 3 — Local container registry

The image never leaves the machine, so a local registry is sufficient and free.

```bash
docker run -d --restart always -p 5000:5000 --name registry registry:2
```

Docker treats `localhost:5000` as an allowed insecure registry by default — no
TLS or daemon configuration is needed. The container restarts automatically with
Docker on boot.

---

## Phase 4 — Application configuration

Clone the repository into the WSL2 home directory (use the native filesystem, not
`/mnt/c`, for build performance). Apply the following changes.

**`config/environments/production.rb`** — uncomment both lines (Cloudflare
terminates TLS):

```ruby
config.assume_ssl = true
config.force_ssl  = true
```

**`config/deploy.yml`** — set the image, server, proxy, and registry:

```yaml
service: litflow
image: litflow

servers:
  web:
    - 127.0.0.1

proxy:
  ssl: false                  # TLS handled at the Cloudflare edge
  host: app.yourdomain.com    # hostname routed via the tunnel

registry:
  server: localhost:5000

ssh:
  user: your-wsl-username     # the Ubuntu user, not root

builder:
  arch: amd64
```

Leave `env`, `volumes`, `asset_path`, and `aliases` unchanged.

**`.kamal/secrets`** — only the master key is required:

```bash
RAILS_MASTER_KEY=$(cat config/master.key)
```

---

## Phase 5 — First deploy

From the repository root inside WSL2:

```bash
bin/kamal setup
```

Verify the app responds locally:

```bash
curl -H "Host: app.yourdomain.com" http://localhost/up   # expect HTTP 200
```

Subsequent deploys: `bin/kamal deploy`.

---

## Phase 6 — Cloudflare Tunnel (DNS)

1. Cloudflare dashboard → **Zero Trust** (accept the free plan on first use).
2. **Networks → Tunnels → Create a tunnel → Cloudflared**. Name it
   `litflow-home` and save.
3. Copy the **token** shown on the install screen.
4. Install the connector. **Run it in only one place — Windows or WSL2, not both.**

   **Option A — Windows service (chosen here).** On the install screen select
   **Windows**, then run the provided command in **PowerShell (Administrator)**.
   It registers `cloudflared` as an auto-starting Windows service. This relies on
   WSL2 localhost forwarding to reach the app (see Notes).

   **Option B — inside WSL2.** Removes the Windows→WSL hop; starts together with
   the app via systemd:

   ```bash
   sudo mkdir -p --mode=0755 /usr/share/keyrings
   curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
   echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(. /etc/os-release && echo $VERSION_CODENAME) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
   sudo apt-get update && sudo apt-get install -y cloudflared
   sudo cloudflared service install <PASTE_TOKEN>
   sudo systemctl enable --now cloudflared
   ```

5. In the tunnel's **Public Hostname** tab, add a hostname:
   - **Subdomain:** `app` (or blank for the root domain) · **Domain:** `yourdomain.com`
   - **Service:** Type `HTTP`, URL `localhost:80`
   - Saving auto-creates the proxied DNS record. No A record or DDNS is needed.
6. **SSL/TLS → Overview:** set encryption mode to **Full** and enable
   **Always Use HTTPS**.

Confirm `https://app.yourdomain.com` serves the app over HTTPS. With Option A,
sanity-check the Windows→WSL hop first, in PowerShell:

```powershell
curl.exe -H "Host: app.yourdomain.com" http://localhost/up   # expect HTTP 200
```

---

## Phase 7 — Resilience (shared personal machine)

- **Disable sleep on AC** — PowerShell (Administrator):

  ```powershell
  powercfg /change standby-timeout-ac 0
  ```

- **Auto-start WSL2 on boot** so systemd brings up Docker, the registry, and the
  app without an interactive login. Create a Task Scheduler task:
  - Trigger: **At startup**
  - Action: program `wsl.exe`, arguments `-d Ubuntu true`
  - Enable **Run whether user is logged on or not** and **Run with highest privileges**

  This boots the distribution; systemd then keeps the long-running services
  alive, and Kamal's containers restart with Docker.

- **cloudflared (Windows service)** auto-starts with Windows on its own. Because
  it starts before WSL2 finishes booting, expect a brief `502` window after a
  reboot until the app is up — this clears automatically. (With Option B,
  cloudflared lives in WSL2 and starts together with the app.)

---

## Verification checklist

- [ ] `systemctl is-system-running` reports running/degraded
- [ ] `docker ps` shows `registry`, `kamal-proxy`, and the `litflow` container
- [ ] `curl -H "Host: app.yourdomain.com" http://localhost/up` returns 200
- [ ] tunnel shows **HEALTHY** in the Cloudflare dashboard
      (Windows: `Get-Service cloudflared`; Option B: `systemctl status cloudflared`)
- [ ] `https://app.yourdomain.com` loads over HTTPS
- [ ] A reboot restores all services automatically

---

## Maintenance

- **Deploy updates:** `git pull && bin/kamal deploy`
- **Logs:** `bin/kamal logs -f`
- **Console / shell:** `bin/kamal console` · `bin/kamal shell`
- **Back up application data:** the `litflow_storage` volume holds the SQLite
  database and Active Storage files — back it up off-machine on a schedule. The
  image is reproducible from the Dockerfile and does not require backup.

## Notes

- If Kamal cannot reach the registry on a fresh boot, confirm the `registry`
  container is running (`docker ps`); it should auto-start via `--restart always`.
- If the app returns "Blocked host", add the domain to `config.hosts` in
  `config/environments/production.rb`.
- **cloudflared on Windows (Option A)** depends on WSL2 localhost forwarding to
  reach kamal-proxy. It is enabled by default; if `localhost:80` does not reach
  the app, enable mirrored networking in `%UserProfile%\.wslconfig` and run
  `wsl --shutdown`:

  ```ini
  [wsl2]
  networkingMode=mirrored
  ```

  If it still fails, switch to Option B (cloudflared inside WSL2).
