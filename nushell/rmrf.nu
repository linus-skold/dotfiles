
def rmrf [
    target: string            # path to remove
    --dry-run (-n)            # print what would be removed, don't delete
    --force  (-f)             # skip the "are you sure?" prompt
] {
    if not ($target | path exists) {
        print $"Path not found: ($target)"
        return
    }

    # fd lists everything (files + dirs) very fast
    print -n "Counting items..."
    let items = (fd --unrestricted . $target | lines | where { |l| ($l | str length) > 0 })
    let total = ($items | length)
    print $"\r  Found ($total) items in ($target)                "

    if $dry_run {
        print "(dry run — nothing deleted)"
        return
    }

    if not $force {
        let answer = (input $"Remove ($total) items from ($target)? [y/N] ")
        if $answer != "y" and $answer != "Y" {
            print "Aborted."
            return
        }
    }

    if $total == 0 {
        rm -rf $target
        print "Done."
        return
    }

    # chunk size: report every ~2% (clamped between 1 and 500)
    let raw_chunk = ($total / 50 | math ceil)
    let chunk_size = if $raw_chunk < 1 { 1 } else if $raw_chunk > 500 { 500 } else { $raw_chunk }
    mut removed = 0

    for chunk in ($items | chunks $chunk_size) {
        $chunk | each { |f| rm -rf $f }
        $removed = $removed + ($chunk | length)
        let pct = ($removed * 100 / $total)
        print -n $"\r  [($pct)%] ($removed)/($total) removed"
    }

    # sweep up any remaining empty dirs
    rm -rf $target
    print $"\r✓ Done — ($total) items removed from ($target)                "
}
