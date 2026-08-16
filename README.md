# Codex Remote Control Kit for Lenovo

A beginner-friendly bridge that lets Codex on a Mac run commands and transfer files on a Lenovo ThinkPad W540 over the local network.

```text
Phone → ChatGPT Remote → Codex on Mac → SSH over local LAN → Lenovo W540
```

This repository is only the remote-control layer. Device-specific tools belong in their own repositories and can be uploaded to the Lenovo later.

## What it does

- Enables Microsoft's OpenSSH Server on Windows 10.
- Restricts SSH connections to devices on the Lenovo's local subnet.
- Creates safe working folders under `C:\CodexRemote`.
- Provides a Mac command named `lenovoctl` for connection tests, commands, uploads, and downloads.
- Provides a read-only diagnostic tool.

It does not install Codex on the Lenovo, open the Lenovo to the public internet, or include any hardware/sniffing software.

## Install on the Lenovo

Requirements: Windows 10 22H2, an administrator account, and internet access during initial setup.

1. Open the [latest release](https://github.com/wgshbd1971/codex-remote-control-lenovo/releases/latest).
2. Under **Assets**, download `codex-remote-control-lenovo-v1.0.0.zip`.
3. Right-click the ZIP and choose **Extract All**.
4. Open the extracted folder.
5. Right-click `INSTALL-LENOVO.cmd` and choose **Run as administrator**.
6. Keep the final window open. It displays the Windows username and local IPv4 address needed by the Mac.

The installer writes the same information to:

```text
C:\CodexRemote\connection-info.txt
```

## Connect from the Mac

Download or clone this repository on the Mac, open Terminal in its folder, and run:

```bash
chmod +x lenovoctl
./lenovoctl configure WINDOWS_USERNAME 192.168.x.x
./lenovoctl test
./lenovoctl info
```

Use the username and IPv4 address shown by the Lenovo installer. The first connection asks you to confirm the Lenovo's host key and then requests the Windows account password. A Windows Hello PIN is not an SSH password.

## Everyday commands

Run a harmless command:

```bash
./lenovoctl run hostname
```

Upload a file or folder into the Lenovo inbox:

```bash
./lenovoctl upload ./my-tool.zip
```

Download a file or folder from the Lenovo outbox:

```bash
./lenovoctl download C:/CodexRemote/outbox/results.zip ./downloads/
```

Open an interactive Windows command prompt:

```bash
./lenovoctl shell
```

## Lenovo folders

```text
C:\CodexRemote\inbox    Files sent from the Mac
C:\CodexRemote\outbox   Results waiting for the Mac
C:\CodexRemote\scripts  Device-specific scripts deployed later
C:\CodexRemote\logs     Tool and diagnostic logs
```

## Diagnostics

On the Lenovo, double-click `DIAGNOSE-LENOVO.cmd`. It checks Windows, network, SSH, firewall, and the working folders without changing anything.

From the Mac:

```bash
./lenovoctl diagnose
```

## Phone control

Phone control is configured on the Mac, not the Lenovo. In the ChatGPT desktop app on the Mac, open **Settings → Connections → Control this Mac or PC**, set up Remote, and pair the ChatGPT mobile app. Keep the Mac awake and online.

## Security

- SSH is reachable only from the Lenovo's local subnet.
- Do not configure port forwarding on the Starlink router.
- Password authentication remains available for initial setup and recovery.
- No passwords or private keys are stored in this repository.
- Device-specific software should use its own repository and safety rules.

See [SECURITY.md](SECURITY.md) for the trust model.

