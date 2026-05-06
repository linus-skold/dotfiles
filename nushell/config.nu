
def initialize [] {
  oh-my-posh init nu --config ~/.dot/oh-my-posh/ember.omp.toml
  zoxide init nushell | save -f ($nu.config-path | path dirname | path join "vendor/autoload/zoxide.nu")
  mise activate nu | save -f ($nu.config-path | path dirname | path join "vendor/autoload/mise.nu")
}


$env.config.show_banner = false

def set_env [key value] {
  ^pwsh -NoProfile -c '[System.Environment]::SetEnvironmentVariable(($key), ($value), "User")'

# System variable (run Nushell as admin)
# ^powershell -Command '[System.Environment]::SetEnvironmentVariable("MY_VAR", "hello", "Machine")'
}
