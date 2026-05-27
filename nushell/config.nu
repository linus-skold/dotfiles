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

def wt-path [] {
    let worktrees = (git worktree list
        | lines
        | each {|line|
            let parts = ($line | split row ' ' | where { |p| $p != '' })
            {
                path: ($parts | get 0),
                hash: ($parts | get 1),
                branch: ($parts | get 2? | default '(detached)')
            }
        }
    )

    $worktrees | select path branch | input list --fuzzy "Select worktree:"
}

def wt-root [] {
    git worktree list
    | lines
    | first
    | split row ' '
    | first
}

def wt-add [
    branch: string,          # existing branch, or name for new branch
    --new: string            # base branch if creating new
] {
    let root = (wt-root)
    let dest = $"($root)/($branch)"

    if ($new | is-empty) {
        git -C $root worktree add $dest $branch
    } else {
        git -C $root worktree add -b $branch $dest $new
    }

    cd $dest
}

# Then use it like:
alias wt = cd (wt-path | get path)

alias fdh = fd -h
alias la = ls -a
alias vi = nvim
alias vim = nvim
alias nv = nvim
# alias dump = obsidian create path="inbox/" content=

alias gco = git worktree add
alias gcl = git clone --bare 

