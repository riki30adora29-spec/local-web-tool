# WSL2 Networking for Local Web Servers

## The problem

WSL2 runs in a lightweight VM with its own virtual network adapter. The Windows host and WSL2
VM get different IPs. While Microsoft provides `localhost` forwarding for most cases, it relies
on the server listening on the right interface.

## Why `app.listen(3000)` breaks

When you call `app.listen(3000)` without a host argument (or with `"localhost"` / `"127.0.0.1"`),
Express binds to the WSL VM's loopback interface only. The Windows host's localhost forwarder
can't reach it because it connects to `::1` / `127.0.0.1` on the *Windows* side, expecting a
WSL-side listener.

The fix: `app.listen(3000, "0.0.0.0")` binds to all interfaces, including the virtual Ethernet
adapter that Windows can reach.

## Debugging checklist

1. **Does it work from inside WSL?**
   ```bash
   curl http://localhost:3000
   ```
   If yes, the server is running correctly. Problem is cross-OS.

2. **Find the WSL IP:**
   ```bash
   ip addr show eth0 | grep 'inet '
   ```
   Example output: `inet 10.213.237.185/24`

3. **Try the WSL IP from Windows browser:**
   `http://10.213.237.185:3000`
   If this works but `localhost:3000` doesn't, localhost forwarding is broken.

4. **Check WSL version:**
   ```bash
   wsl.exe --version
   ```
   WSL1 uses shared networking (localhost works reliably). WSL2 uses NAT (can break).

## Mirrored networking mode (WSL2 ≥ 2.0.0)

When `networkingMode=mirrored` is set in `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
```

WSL2 **shares the Windows host's IP address** — there is no separate WSL IP. `hostname -I`
returns the same IP as the Windows machine. This is the modern recommended mode.

**Implications for local web servers:**

- `localhost` / `127.0.0.1` **always works** — loopback is shared between OSes.
- **Hardcoded WSL IPs break** — `192.168.x.x` addresses that used to work in NAT mode
  are now the Windows machine's own IP. Windows Firewall (especially on Public profile)
  blocks non-loopback inbound connections, so the browser can't reach `http://<ip>:3000`.
- `app.listen(PORT, "0.0.0.0")` is still required — but now it makes the port accessible
  via `localhost` from Windows directly, no NAT traversal needed.

**Detecting mirrored mode:**
```bash
cat /mnt/c/Users/*/.wslconfig | grep networkingMode
# OR check if WSL IP == Windows IP
```

**Debugging workflow for mirrored mode:**

1. Verify server is running inside WSL: `curl http://localhost:3000`
2. Test from Windows side via PowerShell:
   ```powershell
   Invoke-WebRequest -Uri 'http://127.0.0.1:3000/' -UseBasicParsing
   ```
3. If 127.0.0.1 works but the hardcoded IP doesn't → mirrored mode is active.
   **Always use `localhost` in .bat launchers, never a hardcoded IP.**

## Alternative: netsh port forwarding (last resort for NAT mode only)

If you're on the older NAT mode and neither `0.0.0.0` nor direct IP access works, set up a Windows port forward:

```powershell
# In Windows PowerShell (Admin):
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=<WSL_IP>
```

Remove when done:
```powershell
netsh interface portproxy delete v4tov4 listenport=3000 listenaddress=0.0.0.0
```

Note: netsh portproxy is NOT needed in mirrored mode — localhost works natively.
