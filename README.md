# Codex Remote Control Kit for Lenovo

This kit makes the Lenovo ThinkPad W540 the **remote/field computer** and the MacBook the **development/control station**. It is a general remote-control and software-deployment kit; the serial recorder is its first tool, not the identity of the whole kit.

```text
MacBook / Codex  ------ SSH over LAN ------>  Lenovo W540 / Windows
                                              |
                                              +-- USB-RS232/RS485 adapter
                                              +-- ECM-55
```

The Lenovo can run deployed tools without an internet connection. Because both computers use the same Starlink local network, SSH is used directly and Tailscale is not required.

## 1. One-time Lenovo setup

1. On the Lenovo, open **PowerShell as Administrator**.
2. Copy this folder to the Lenovo (a USB stick is fine for the first setup).
3. In PowerShell, enter:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\setup-lenovo.ps1
   ```

4. Find the Lenovo's local IPv4 address with `ipconfig` and its Windows username with `$env:USERNAME`.

The setup script enables Windows OpenSSH, installs Python if needed, creates `C:\CodexRemote`, and installs `pyserial` in a private virtual environment.

## 2. Set up the Mac

Open Terminal in this folder:

```bash
chmod +x lenovoctl
./lenovoctl configure WINDOWS_USERNAME 192.168.x.x
./lenovoctl test
```

On the first connection, verify and accept the SSH host fingerprint. Windows will ask for the Windows account password. For password-free operation:

```bash
ssh-keygen -t ed25519
ssh-copy-id WINDOWS_USERNAME@100.x.y.z
```

If `ssh-copy-id` is unavailable, see “SSH key setup” below.

## 3. Deploy and use

```bash
./lenovoctl deploy
./lenovoctl ports
./lenovoctl capture COM3 9600 60
./lenovoctl fetch
```

- Replace `COM3` and `9600` with the real adapter port and ECM-55 baud rate.
- `capture` is receive-only and writes timestamped binary and text/hex logs on the Lenovo.
- `fetch` copies all logs into `retrieved-logs/` on the Mac.
- A capture continues on the Lenovo if the SSH connection drops.

Check and stop captures:

```bash
./lenovoctl status
./lenovoctl stop
```

Run a job interactively while diagnosing something:

```bash
./lenovoctl capture-live COM3 9600 30
```

## 4. Offline shed workflow

Before leaving Wi-Fi:

```bash
./lenovoctl deploy
./lenovoctl ports
```

At the Lenovo, open PowerShell and run:

```powershell
C:\CodexRemote\.venv\Scripts\python.exe C:\CodexRemote\current\serial_recorder.py ports
C:\CodexRemote\.venv\Scripts\python.exe C:\CodexRemote\current\serial_recorder.py capture --port COM3 --baud 9600 --seconds 120
```

Later, reconnect both machines and run `./lenovoctl fetch` on the Mac.

## Safety and RS-485 notes

- The included capture command never transmits; start by listening only.
- Confirm voltage levels before connecting. RS-232 is not TTL serial and must not be wired directly to TTL pins.
- For RS-485, connect A/B according to the adapter/device documentation; A/B naming is unfortunately not universal. Add signal ground where required.
- Avoid adding termination or bias resistors until the existing bus topology is understood.
- Start with a USB adapter that provides galvanic isolation when working near industrial equipment.
- We still need the ECM-55 manual or known settings to add frame decoding: baud, data bits, parity, stop bits, RS-232 versus two/four-wire RS-485, and any request/response commands.

## SSH key setup without `ssh-copy-id`

On the Mac, display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

On the Lenovo, create `%USERPROFILE%\.ssh\authorized_keys` and paste that one-line key into it. For an administrator account, Windows OpenSSH may instead use `C:\ProgramData\ssh\administrators_authorized_keys`; Windows ACLs must allow only Administrators and SYSTEM. Password login is acceptable for initial testing.

## Configuration

`lenovoctl configure` writes `.lenovo-device`, which is deliberately excluded by `.gitignore`. It contains the Lenovo SSH address and username, not a password. Keep private keys in the normal `~/.ssh` directory—never in this project.
