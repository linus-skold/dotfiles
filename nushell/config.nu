# This file is loaded after env.nu and before login.nu
# See `help config nu` for more options

$env.config.show_banner = false

$env.EDITOR = 'nvim'
$env.VISUAL = 'nvim'
$env.SOPS_AGE_KEY_FILE = ('~/.config/sops/age/key.txt' | path expand ) 


$env.PATH = ($env.PATH | append ("~/.local/bin" | path expand))


def initialize [] {
  oh-my-posh init nu --config ~/.dot/oh-my-posh/ember.omp.toml
  zoxide init nushell | save -f ($nu.config-path | path dirname | path join "vendor/autoload/zoxide.nu")
  mise activate nu | save -f ($nu.config-path | path dirname | path join "vendor/autoload/mise.nu")
}

source "./worktree/mod.nu"
source "./rmrf.nu"

# alias dump = obsidian create path="inbox/" content=
def zi [] {
    let dir = (
        zoxide query -l
        | fzf --preview "ls {}" --height 40% --reverse --border
        | str trim
    )

    if ($dir | is-not-empty) {
        print $dir
        cd $dir
    }
}

alias fdh = fd -h
alias la = ls -a
alias vi = nvim
alias vim = nvim
alias nv = nvim

alias gco = git worktree add
alias gcl = git clone --bare 

