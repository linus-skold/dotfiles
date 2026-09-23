
Import-Module WebAdministration

Get-Website | ForEach-Object {
    $site = $_
    $bindings = ($site.Bindings.Collection | ForEach-Object {
        $_.bindingInformation
    }) -join "; "

    [PSCustomObject]@{
        Name        = $site.Name
        State       = $site.State
        PhysicalPath= $site.PhysicalPath
        Bindings    = $bindings
    }
}
