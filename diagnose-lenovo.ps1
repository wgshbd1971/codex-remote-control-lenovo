$ErrorActionPreference = 'Continue'
$root = 'C:\CodexRemote'

Write-Host 'Codex Remote Control Kit - Lenovo Diagnostics' -ForegroundColor Cyan
Write-Host ('Time: ' + (Get-Date))
Write-Host ('Computer: ' + $env:COMPUTERNAME)
Write-Host ('Windows user: ' + $env:USERNAME)
Write-Host ('Windows: ' + [Environment]::OSVersion.VersionString)

Write-Host "`nIPv4 addresses:" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*'
    } |
    Format-Table InterfaceAlias, IPAddress -AutoSize

Write-Host 'SSH service:' -ForegroundColor Cyan
Get-Service sshd -ErrorAction SilentlyContinue |
    Format-Table Status, StartType, Name -AutoSize

Write-Host 'Local-subnet firewall rule:' -ForegroundColor Cyan
Get-NetFirewallRule -Name 'CodexRemote-SSH-LocalSubnet' -ErrorAction SilentlyContinue |
    Format-Table Enabled, Direction, Action, Profile -AutoSize

Write-Host 'Working folders:' -ForegroundColor Cyan
$folderStatus = foreach ($folder in 'inbox', 'outbox', 'scripts', 'logs') {
    $path = Join-Path $root $folder
    [PSCustomObject]@{
        Folder = $path
        Present = Test-Path $path
    }
}
$folderStatus | Format-Table -AutoSize

Write-Host 'SSH port listener:' -ForegroundColor Cyan
Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue |
    Format-Table LocalAddress, LocalPort, State -AutoSize
