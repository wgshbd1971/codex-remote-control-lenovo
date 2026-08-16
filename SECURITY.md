# Security model

This kit grants the configured Windows account remote command and file access over SSH. Treat that access like sitting at the Lenovo keyboard.

## Network boundary

The installer disables Windows' broad default OpenSSH firewall rule and creates a replacement restricted to `LocalSubnet`. Do not add Starlink router port forwarding for TCP port 22.

## Authentication

Version 1.0 keeps Windows password authentication enabled for straightforward setup and recovery. Use a strong Windows account password. A later release may provide guided SSH-key enrollment after the basic connection has been verified.

## Files and secrets

- Never commit passwords, private keys, captured device data, or customer data.
- Use `C:\CodexRemote\inbox` for incoming packages and `outbox` for results.
- Review device-specific scripts in their own repository before deploying them.
- Keep Windows Defender and available Windows security updates enabled.

## Scope

This repository contains no device-specific tooling or automatic code execution service. Commands run only when initiated through an authenticated SSH connection.
