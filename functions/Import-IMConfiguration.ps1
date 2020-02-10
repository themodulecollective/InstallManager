function Import-IMConfiguration
{
    $script:IMConfiguration = Get-PSFConfigValue -FullName "$($MyInvocation.MyCommand.ModuleName).Preferences"
}