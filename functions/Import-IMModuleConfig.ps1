function Import-IMModuleConfig
{
    $script:IMConfiguration = Import-Configuration
    [System.Collections.Generic.List[object]]$script:ManagedInstalls =
    @( #this ensures the array is created
        $script:IMConfiguration.Definitions |
        ForEach-Object {
            if ($_.psobject.TypeNames[0] -ne 'IMDefinition')
            {
                $_.psobject.TypeNames.insert(0, 'IMDefinition')
            }
            $_
        }
    )
}