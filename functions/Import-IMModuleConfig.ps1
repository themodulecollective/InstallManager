function Import-IMModuleConfig
{
    $script:IMConfiguration = Import-Configuration
    $script:ManagedInstalls = $script:IMConfiguration.Definitions
}