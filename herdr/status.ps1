[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$out = tt status 2>$null | Out-String
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($out -notmatch 'Currently tracking: "(.*)"') { exit 1 }   # not tracking → hide

$title = $Matches[1]
#if ($title.Length -gt 30) { $title = $title.Substring(0, 30) }

$project = if ($out -match '(?m)^\s*Project:\s*(.+?)\s*$') { $Matches[1] } else { '' }
$dur     = if ($out -match '(?m)^\s*Duration:\s*(.+?)\s*$') { $Matches[1] -replace '^0h ', '' } else { '' }

$clock = [char]0x23F1   # ⏱
# $dot   = [char]0x00B7   # ·
$dot   = [char]0x2022   # •
$pad = [string][char]0x2800 * 2

$parts = @($title, $project, $dur) | Where-Object { $_ }
Write-Output "$clock  $($parts -join " $dot ")$pad"

