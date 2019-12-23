Function Import-IMDefinition
{

    [cmdletbinding()]
    param(
    )

    $RequiredProperties = @('Name', 'InstallManager', 'RequiredVersion', 'AutoUpgrade', 'AutoRemove', 'ExemptMachine', 'Parameter', 'Repository')
    #$Script:ManagedInstalls = $ManagedInstalls

}
