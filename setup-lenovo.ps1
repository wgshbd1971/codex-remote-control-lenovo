#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

Write-Host "Installing and enabling Windows OpenSSH Server..."
$capability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($null -eq $capability) { throw "OpenSSH Server capability is unavailable on this Windows installation." }
if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capability.Name
}
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Python with winget..."
        winget install --id Python.Python.3.12 --exact --accept-package-agreements --accept-source-agreements
        $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    } else {
        throw "Python is missing and winget is unavailable. Install Python 3 from python.org, then rerun this script."
    }
}

$root = 'C:\CodexRemote'
New-Item -ItemType Directory -Force -Path $root, "$root\current", "$root\logs", "$root\run" | Out-Null
if (-not (Test-Path "$root\.venv\Scripts\python.exe")) {
    python -m venv "$root\.venv"
}
& "$root\.venv\Scripts\python.exe" -m pip install --upgrade pip
if (Test-Path "$PSScriptRoot\requirements.txt") {
    & "$root\.venv\Scripts\python.exe" -m pip install -r "$PSScriptRoot\requirements.txt"
} else {
    & "$root\.venv\Scripts\python.exe" -m pip install 'pyserial>=3.5,<4'
}

Write-Host ""
Write-Host "Lenovo remote-control environment ready."
Write-Host "Windows user: $env:USERNAME"
Write-Host "Local network information:"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -notlike '127.*' | Select-Object InterfaceAlias, IPAddress
