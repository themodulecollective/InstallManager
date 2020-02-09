function Import-IMModuleConfig
{
    $script:IMConfiguration = Get-PSFConfigValue -FullName "$($MyInvocation.MyCommand.ModuleName).Preferences"

}