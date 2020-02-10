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

    [cmdletbinding(DefaultParameterSetName = 'All')]
    param(
        # Use to specify the name of the InstallManager Definition(s) to get.  Accepts Wildcard.
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name', Position = 1)]
        [string[]]$Name
        ,
        # Use to specify the Install Manager for the Definition(s) to get.   Used primarily for filtering in bulk operations or when multiple
        [parameter(ValueFromPipelineByPropertyName, Position = 2)]
        [InstallManager[]]$InstallManager
    )

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Name'
            {
                foreach ($n in $Name)
                {
                    switch ($InstallManager.count)
                    {
                        0
                        {
                            (Get-PSFConfig -Module InstallManager -Name Definitions.*.$($n)).foreach( { Get-PSFConfigValue -FullName $_.FullName })
                        }
                        Default
                        {
                            foreach ($im in $InstallManager)
                            {
                                (Get-PSFConfig -Module InstallManager -Name Definitions.$($im).$($n)).foreach( { Get-PSFConfigValue -FullName $_.FullName })
                            }
                        }
                    }
                }
            }
            'All'
            {
                switch ($InstallManager.count)
                {
                    0
                    {
                        (Get-PSFConfig -Module InstallManager -Name Definitions.*).foreach( { Get-PSFConfigValue -FullName $_.FullName })
                    }
                    Default
                    {
                        foreach ($im in $InstallManager)
                        {
                            (Get-PSFConfig -Module InstallManager -Name Definitions.$($im).*).foreach( { Get-PSFConfigValue -FullName $_.FullName })
                        }
                    }
                }
            }
        }
    }
}
