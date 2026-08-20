
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

def --env wt-add [
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

# Search file contents across all worktrees with ripgrep.
# Usage: wt-rg <pattern> [--type <ext>]
# Pick a match from the list → cd into that worktree.
def wt-rg [
    pattern: string,          # regex / literal to search for
    --type (-t): string       # optional: file type filter, e.g. 'ts', 'rs', 'py'
] {
    let worktrees = (git worktree list
        | lines
        | each {|line|
            let parts = ($line | split row ' ' | where { |p| $p != '' })
            {
                path:   ($parts | get 0),
                branch: ($parts | get 2? | default '(detached)')
            }
        }
    )

    let type_args = if ($type | is-empty) { [] } else { ["--type" $type] }

    let hits = (
        $worktrees | each {|wt|
            let raw = (do { rg --line-number --with-filename $pattern $wt.path ...$type_args } | complete)
            if $raw.exit_code == 0 {
                $raw.stdout
                | lines
                | each {|l|
                    # strip the absolute worktree prefix so the path shown is relative
                    let rel = ($l | str replace $"($wt.path)/" '')
                    { display: $"[($wt.branch)]  ($rel)", path: $wt.path }
                }
            } else { [] }
        }
        | flatten
    )

    if ($hits | is-empty) {
        print $"No matches for '($pattern)'"
        return
    }

    let chosen = ($hits | input list --fuzzy $"rg '($pattern)' — pick a match:")
    cd $chosen.path
}

# Find files by name across all worktrees.
# Usage: wt-find <glob>   e.g.  wt-find '*.ts'  or  wt-find 'index.html'
# Pick a result → cd into that worktree.
def wt-find [
    glob: string              # filename glob / substring to search for
] {
    let worktrees = (git worktree list
        | lines
        | each {|line|
            let parts = ($line | split row ' ' | where { |p| $p != '' })
            {
                path:   ($parts | get 0),
                branch: ($parts | get 2? | default '(detached)')
            }
        }
    )

    let hits = (
        $worktrees | each {|wt|
            let raw = (do { fd --full-path $glob $wt.path } | complete)
            if $raw.exit_code == 0 {
                $raw.stdout
                | lines
                | where { |l| ($l | str length) > 0 }
                | each {|l|
                    let rel = ($l | str replace $"($wt.path)/" '')
                    { display: $"[($wt.branch)]  ($rel)", path: $wt.path }
                }
            } else { [] }
        }
        | flatten
    )

    if ($hits | is-empty) {
        print $"No files matching '($glob)'"
        return
    }

    let chosen = ($hits | input list --fuzzy $"find '($glob)' — pick a file:")
    cd $chosen.path
}

# Pick a remote branch with fzf (preview: recent commits) and add it as a new worktree.
def --env wt-pick [] {
    let root = (wt-root)

    git fetch --all
    let branch = (
        git branch -r
        | lines
        | str trim
        | str replace --regex '^\* ' ''
        | where { |b| ($b | str length) > 0 and not ($b | str contains "HEAD") }
        | str join "\n"
        | fzf --header "Add Worktree from Remote Branch" --preview "git log --color=always --oneline -15 {}"
        | str trim
        | str replace --regex '^origin/' ''
    )

    if ($branch | is-empty) { return }

    let dest = $"($root)/($branch)"
    git worktree add $dest $branch
    cd $dest
}

# Remove one or more worktrees interactively.
# Tab to multi-select, Enter to confirm, --force to remove dirty trees.
def wt-rm [
    --force (-f)              # pass --force to git worktree remove
] {
    let worktrees = (git worktree list
        | lines
        | each {|line|
            let parts = ($line | split row ' ' | where { |p| $p != '' })
            {
                path:   ($parts | get 0),
                branch: ($parts | get 2? | default '(detached)')
            }
        }
    )

    # never offer the main worktree (first entry) for deletion
    let removable = ($worktrees | skip 1)

    if ($removable | is-empty) {
        print "No worktrees to remove (only the main worktree exists)."
        return
    }

    let chosen = (
        $removable
        | input list --fuzzy --multi "Select worktrees to remove (Tab to select, Enter to confirm):"
    )

    if ($chosen | is-empty) {
        print "Nothing selected."
        return
    }

    let force_flag = if $force { ["--force"] } else { [] }

    $chosen | each {|wt|
        print $"Removing [($wt.branch)]  ($wt.path)"
        git worktree remove ...$force_flag $wt.path
    }

    git worktree prune
    print $"Done. ($chosen | length) worktrees removed."
}

# Then use it like:
def --env wt [] {
    let selection = (wt-path)
    if ($selection | is-empty) { return }
    cd $selection.path
}
