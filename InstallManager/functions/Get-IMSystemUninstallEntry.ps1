Function Get-IMSystemUninstallEntry
{
    <#
.SYNOPSIS
    Gets all uninstall entries from the windows registry
.DESCRIPTION
    Gets all uninstall entries from the windows registry
.EXAMPLE
    PS C:\> Get-IMSystemUninstallEntry
    Gets a powershell object with a specified set of properties for each uninstall entry found in the windows registry.  Change the set of properties with the SpecifiedProperties parameter.
.EXAMPLE
    PS C:\> Get-IMSystemUninstallEntry -raw
    Gets a powershell object with all available properties for each uninstall entry found in the windows registry
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [cmdletbinding(DefaultParameterSetName = 'SpecifiedProperties')]
    param(
        # Use to return all available properties for each uninstall entry
        [parameter(ParameterSetName = 'Raw')]
        [switch]$Raw
        ,
        # Use to override the default set of properties included with the uninstall entry output objects
        [parameter(ParameterSetName = 'SpecifiedProperties')]
        [string[]]$Property = @('DisplayName', 'DisplayVersion', 'InstallDate', 'Publisher')
    )
    # paths: x86 and x64 registry keys are different
    if ([IntPtr]::Size -eq 4)
    {
        $path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else
    {
        $path = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    $UninstallEntries = Get-ItemProperty $path
    # use only with name and unistall information
    #.{process{ if ($_.DisplayName -and $_.UninstallString) { $_ } }} |
    # select more or less common subset of properties
    #Select-Object DisplayName, Publisher, InstallDate, DisplayVersion, HelpLink, UninstallString |
    # and finally sort by name
    #Sort-Object DisplayName
    if ($Raw) { $UninstallEntries | Sort-Object -Property DisplayName }
    else
    {
        $UninstallEntries | Sort-Object -Property DisplayName | Select-Object -Property $Property
    }

}
