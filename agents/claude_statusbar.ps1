# Claude Code status line: model | context bar | agent memory bar | running subagents.
# Reads the status line JSON from stdin. Needs pwsh 7 (Process.Parent) and a truecolor terminal.

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tunables
$BarWidth    = 12     # cells per bar
$MemBudgetMB = 2048   # memory that fills the memory bar

$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

$esc   = [char]27
$reset = "$esc[0m"
$dim   = "$esc[2m"
$bold  = "$esc[1m"
function Fg($rgb) { "$esc[38;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m" }

# Gradient stops: green -> yellow -> orange -> red
$stops = @(
    @(0.00, @(80, 200, 120)),
    @(0.50, @(230, 210, 80)),
    @(0.75, @(240, 150, 60)),
    @(1.00, @(235, 70, 80))
)
function Gradient([double]$t) {
    $t = [math]::Max(0.0, [math]::Min(1.0, $t))
    for ($i = 1; $i -lt $stops.Count; $i++) {
        if ($t -le $stops[$i][0]) {
            $a = $stops[$i - 1]; $b = $stops[$i]
            $f = ($t - $a[0]) / ($b[0] - $a[0])
            return @(0..2 | ForEach-Object { [int]($a[1][$_] + ($b[1][$_] - $a[1][$_]) * $f) })
        }
    }
    $stops[-1][1]
}

# Each filled cell takes the gradient colour of its position, so the bar warms up as it fills.
# The last cell uses an eighth block for sub-cell precision.
$full     = [char]0x2588
$partials = @('', [char]0x258F, [char]0x258E, [char]0x258D, [char]0x258C, [char]0x258B, [char]0x258A, [char]0x2589)
$empty    = [char]0x2591
function Bar([double]$pct) {
    $fill  = [math]::Max(0.0, [math]::Min(100.0, $pct)) / 100 * $BarWidth
    $whole = [math]::Floor($fill)
    $rest  = [int][math]::Floor(($fill - $whole) * 8)
    $out = ''
    for ($i = 0; $i -lt $BarWidth; $i++) {
        $col = Fg (Gradient (($i + 0.5) / $BarWidth))
        if ($i -lt $whole)                  { $out += "$col$full" }
        elseif ($i -eq $whole -and $rest)   { $out += "$col$($partials[$rest])" }
        else                                { $out += "$esc[38;2;70;70;80m$empty" }
    }
    "$out$reset"
}
function Label([double]$pct, $text) { "$(Fg (Gradient ($pct / 100)))$text$reset" }

# Model
$model = $data.model.display_name
if (-not $model) { $model = $data.model.id }

# Context usage
$cw   = $data.context_window
$size = [double]$cw.context_window_size
$pct  = $cw.used_percentage
if ($null -eq $pct -and $size -gt 0 -and $cw.current_usage) {
    $u = $cw.current_usage
    $used = [double]$u.input_tokens + [double]$u.cache_creation_input_tokens + [double]$u.cache_read_input_tokens
    $pct = 100 * $used / $size
}
if ($null -ne $pct) {
    $pct = [double]$pct
    $ctx = "${dim}ctx$reset $(Bar $pct) $(Label $pct ('{0,3:0}%' -f $pct))"
    if ($size -gt 0) { $ctx += "$dim/$([math]::Round($size / 1000))k$reset" }
} else {
    $ctx = "${dim}ctx $(Bar 0) --$reset"
}

# Agent memory: working set of the nearest claude/node/bun ancestor process
$mem = "${dim}mem $(Bar 0) --$reset"
$cur = Get-Process -Id $PID
for ($i = 0; $cur -and $i -lt 10; $i++) {
    $cur = $cur.Parent
    if ($cur -and $cur.ProcessName -match '^(claude|node|bun)$') {
        $mb   = [double]$cur.WorkingSet64 / 1MB
        $mpct = 100 * $mb / $MemBudgetMB
        $text = if ($mb -ge 1024) { '{0:0.0}GB' -f ($mb / 1024) } else { '{0:0}MB' -f $mb }
        $mem  = "${dim}mem$reset $(Bar $mpct) $(Label $mpct $text)"
        break
    }
}

# Running subagents: transcripts without a SubagentStop marker, written to recently
$agents = 0
if ($data.transcript_path) {
    $subDir = Join-Path ([IO.Path]::ChangeExtension($data.transcript_path, $null).TrimEnd('.')) 'subagents'
    $cutoff = (Get-Date).AddMinutes(-10)
    Get-ChildItem -Path $subDir -Filter 'agent-*.jsonl' |
        Where-Object { $_.LastWriteTime -gt $cutoff } |
        ForEach-Object {
            $tail = (Get-Content -LiteralPath $_.FullName -Tail 5) -join "`n"
            if ($tail -notmatch '"hookEvent":"SubagentStop"') { $agents++ }
        }
}
# One lit dot per running agent
$dot = [char]0x25CF
$agentsOut = if ($agents -gt 0) {
    "$(Fg @(100, 190, 240))$($dot.ToString() * [math]::Min($agents, 8)) $agents agent$(if ($agents -ne 1) { 's' })$reset"
} else {
    "${dim}$([char]0x25CB) idle$reset"
}

$sep = " $dim$([char]0x2502)$reset "
Write-Output ("$bold$(Fg @(200, 160, 255))$model$reset" + $sep + $ctx + $sep + $mem + $sep + $agentsOut)
