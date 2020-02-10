Function Import-IMDefinition
{
    <#
.SYNOPSIS
    Imports definitions from a file produced by Export-IMDefition.  WARNING: Overwrites any existing definition with the same name and InstallManager as an imported definition.
.DESCRIPTION
    Imports definitions from a file produced by Export-IMDefition.  WARNING: Overwrites any existing definition with the same name and InstallManager as an imported definition.
.EXAMPLE
    Import-IMDefinition -FilePath c:\LocalOnly\cdefinitions.json
    Imports all the definitions in the specified file.
.INPUTS
.OUTPUTS
.NOTES
#>
    [cmdletbinding()]
    param
    (
        #Specify the file to Import, should be json format, exported with Export-IMDefinition.
        [Parameter(Mandatory)]
        [ValidateScript( { Test-Path -PathType Leaf -Path $_ })]
        $FilePath
        ,
        #If specified, only Definitions with names that are similar (-like) to names in this list will be imported.
        [parameter()]
        [string[]]$IncludeFilter
        ,
        #Definitions that are similar (-like) to names in this list will NOT be imported.
        [parameter()]
        [string[]]$ExcludeFilter
    )

    #$RequiredProperties = @('Name', 'InstallManager', 'RequiredVersion', 'AutoUpgrade', 'AutoRemove', 'ExemptMachine', 'Parameter', 'Repository', 'Scope')
    #Write-Information -MessageData "The required properties for IMDefinition(s) are: $($RequiredProperties -join ',')"
    $impConfigParams = @{
        AllowDelete = $true
        Path = $FilePath
        PassThru = $true
    }
    if ($IncludeFilter.count -ge 1)
    {
        $impConfigParams.IncludeFilter = $IncludeFilter
    }
    if ($ExcludeFilter.count -ge 1)
    {
        $impConfigParams.ExcludeFilter = $ExcludeFilter
    }

    Import-PSFConfig @impConfigParams |
    Register-PSFConfig

}
