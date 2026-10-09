[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Show the git branch of the focused herdr pane. Exit 1 hides the segment.
$json = herdr pane list 2>$null | Out-String
if ($LASTEXITCODE -ne 0) { exit 1 }

try { $panes = ($json | ConvertFrom-Json).result.panes } catch { exit 1 }
$pane = @($panes | Where-Object { $_.focused }) | Select-Object -First 1
if (-not $pane -or -not $pane.cwd) { exit 1 }
$cwd = $pane.cwd

$branch = (git -C $cwd branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { exit 1 }
if (-not $branch) {
    $branch = (git -C $cwd rev-parse --short HEAD 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $branch) { exit 1 }
}

$glyph = [char]0xE0A0
$pad = [string][char]0x2800 * 2
Write-Output "$glyph  $branch$pad"
