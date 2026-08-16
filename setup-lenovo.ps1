#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = 'C:\CodexRemote'
$installLog = Join-Path $env:TEMP 'codex-remote-lenovo-install.log'

function Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

Start-Transcript -Path $installLog -Force | Out-Null
try {
    Step 'Checking Windows version'
    $build = [Environment]::OSVersion.Version.Build
    if ($build -lt 17763) {
        throw "Windows build $build is too old. Windows 10 build 1809 or later is required."
    }
    Write-Host "Windows build: $build"

    Step 'Installing and enabling Microsoft OpenSSH Server'
    $capability = Get-WindowsCapability -Online |
        Where-Object Name -Like 'OpenSSH.Server*' |
        Select-Object -First 1
    if ($null -eq $capability) {
        throw 'The Windows OpenSSH Server optional capability is unavailable.'
    }
    if ($capability.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name $capability.Name | Out-Null
    }
    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd

    Step 'Restricting SSH to the local network'
    Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue |
        Disable-NetFirewallRule
    Get-NetFirewallRule -Name 'CodexRemote-SSH-LocalSubnet' -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule
    New-NetFirewallRule `
        -Name 'CodexRemote-SSH-LocalSubnet' `
        -DisplayName 'Codex Remote - SSH from local subnet only' `
        -Enabled True `
        -Profile Any `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 22 `
        -RemoteAddress LocalSubnet `
        -Action Allow | Out-Null

    Step 'Creating remote-control folders'
    $folders = @(
        $root,
        (Join-Path $root 'inbox'),
        (Join-Path $root 'outbox'),
        (Join-Path $root 'scripts'),
        (Join-Path $root 'logs')
    )
    New-Item -ItemType Directory -Force -Path $folders | Out-Null
    Set-Content -Path (Join-Path $root 'VERSION') -Value '1.0.0' -Encoding ASCII
    Copy-Item -Force (Join-Path $PSScriptRoot 'diagnose-lenovo.ps1') (Join-Path $root 'scripts')

    Step 'Writing connection information'
    $addresses = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*'
        } |
        Select-Object InterfaceAlias, IPAddress
    $info = @(
        'Codex Remote Control Kit for Lenovo',
        'Version: 1.0.0',
        "Computer: $env:COMPUTERNAME",
        "Windows user: $env:USERNAME",
        'Local IPv4 addresses:',
        ($addresses | Format-Table -AutoSize | Out-String).TrimEnd(),
        '',
        'Keep this information for the Mac setup.'
    ) -join "`r`n"
    Set-Content -Path (Join-Path $root 'connection-info.txt') -Value $info -Encoding UTF8

    Step 'Verifying SSH service'
    $service = Get-Service sshd
    if ($service.Status -ne 'Running') {
        throw 'The SSH service was installed but is not running.'
    }

    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host ' LENOVO SETUP COMPLETE' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host $info
    Write-Host "`nSaved to C:\CodexRemote\connection-info.txt"
    Write-Host "Installation log: $installLog"
} catch {
    Write-Host "`nINSTALLATION FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Installation log: $installLog" -ForegroundColor Yellow
    exit 1
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}

