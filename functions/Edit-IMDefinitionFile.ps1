Function Edit-IMDefinitionFile
{
    <#
    .SYNOPSIS
        Opens the IMDefinitionFile with the default editor
    .DESCRIPTION
        Opens the IMDefinitionFile with the default editor.  Consider setting a default path for the IMDefinitionFile in your profile with $PSDefaultParameterValues.'Edit-IMDefinitionFile:Path' = $ManagedInstallsFilePath
    .EXAMPLE
        Edit-IMDefinitionFile -Path c:\Users\UserName\MyInstallDefinitions.csv
        Opens the InstallManager definitions file in the default editor for csv files
    .PARAMETER Path
        Specify the path to the InstallManager Definitions file to edit with the default editor
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [cmdletbinding()]
    [OutputType()]
    param
    (
        [parameter()]
        [ValidateScript( { Test-Path -Path $_ -Type Leaf })]
        [string]$Path
    )

    Invoke-Item $Path

}
