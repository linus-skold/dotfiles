#$EDITOR = nvim
$env.EDITOR = 'nvim'
$env.VISUAL = 'nvim'
$env.config.show_banner = false

def initialize [] {
  oh-my-posh init nu --config ~/.dot/oh-my-posh/ember.omp.toml
  zoxide init nushell | save -f ($nu.config-path | path dirname | path join "vendor/autoload/zoxide.nu")
  mise activate nu | save -f ($nu.config-path | path dirname | path join "vendor/autoload/mise.nu")
}

def set_env [key: string, value: string, scope: string = "User"] {
  if $scope not-in ["User", "Machine", "Process"] {
    error make { msg: $"Invalid scope '($scope)'. Must be User, Machine, or Process." }
  }
  load-env {($key): $value}
  let cmd = $"[System.Environment]::SetEnvironmentVariable\('($key)', '($value)', '($scope)'\)"
  ^pwsh -NoProfile -c $cmd
}

def dump [textdump: string] {
# check if file already exists
  if ('~/vault/inbox/dump.md' | path exists) {
    obsidian append path="inbox/dump.md" content=$"($textdump)"
  } else {
    obsidian create path="inbox/dump.md" content=$"($textdump)"
  }
}


# Append one or more todo items to today's Obsidian daily note
def "td add" [...tasks: string] {
  if ($tasks | is-empty) {
    error make { msg: "Usage: td add \"Task one\" \"Task two\"" }
  }
  let content = ($tasks | each { |t| $"- [ ] ($t)" } | str join "\n")
  obsidian daily:append content=$"($content)"
}

alias fdh = fd -h
alias la = ls -a
alias vi = nvim
alias vim = nvim
alias nv = nvim
# alias dump = obsidian create path="inbox/" content=


