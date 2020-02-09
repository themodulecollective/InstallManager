Function Import-IMDefinition
{

    [cmdletbinding()]
    param(
    )

    $RequiredProperties = @('Name', 'InstallManager', 'RequiredVersion', 'AutoUpgrade', 'AutoRemove', 'ExemptMachine', 'Parameter', 'Repository', 'Scope')
    Write-Information -MessageData "The required properties for IMDefinition(s) are: $($RequiredProperties -join ',')"

}
