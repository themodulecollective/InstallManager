Function Get-IMDefinition
{
    <#
    .SYNOPSIS
        Gets the Install Manager Definitions.  If no definitions have been imported yet, returns nothing.  Use Import-IMDefinition to import Install Manager Definitions.
    .DESCRIPTION
        Gets the Install Manager Definitions.  If no definitions have been imported yet, returns nothing.  Use Import-IMDefinition to import Install Manager Definitions.
    .EXAMPLE
        Get-IMDefinition -Name Terminal-Icons

        Name            : Terminal-Icons
        InstallManager  : PowerShellGet
        RequiredVersion :
        AutoUpgrade     : True
        AutoRemove      : True
        ExemptMachine   :
        Parameter       :
        Repository      : PSGallery

        Gets the InstallManager definition for the Terminal-Icons PowerShell Module
    .EXAMPLE
        Get-IMDefinition -InstallManager PowerShellGet

        Name            : Terminal-Icons
        InstallManager  : PowerShellGet
        RequiredVersion : 0.0.4;0.0.5
        AutoUpgrade     : True
        AutoRemove      : True
        ExemptMachine   :
        Parameter       :
        Repository      : PSGallery

        Gets the InstallManager definitions for all definitions where InstallManager is PowerShellGet

    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>

    [cmdletbinding()]
    param(
        [string]$Name
        ,
        [InstallManager[]]$InstallManager
    )
    #$InstallManagers = @($InstallManager.foreach('ToString'))
    $Script:ManagedInstalls.where( { ([string]::IsNullOrEmpty($Name) -or $_.Name -like $Name) }).where( { $InstallManager.count -eq 0 -or $_.InstallManager -in $InstallManager })
}
