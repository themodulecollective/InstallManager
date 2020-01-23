function Import-IMModuleConfig
{
    $script:IMConfiguration = Import-Configuration
    [System.Collections.Generic.List[object]]$script:ManagedInstalls = $script:IMConfiguration.Definitions
}