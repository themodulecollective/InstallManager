function Export-IMDefinition
{
  <#
  .SYNOPSIS
    Export one or more Install Manager Definitions to a json formatted file for import using Import-IMDefinition
  .DESCRIPTION
    Export one or more Install Manager Definitions to a json formatted file for import using Import-IMDefinition.  Used for export/import scenarios between systems where the same configuration is desired.
  .EXAMPLE
    Export-IMDefinition -InstallManager Chocolatey -Path c:\local\IMChocoDefinitions.json
    Exports all Chocolatey Install Manager definitions to the specifed json file.
  .EXAMPLE
    Export-IMDefinition -Name rufus,textmate,UniversalDashboard -Path c:\local\IMDefinitions.json
    Exports Install Manager definitions for rufus, textmate, and UniversalDashboard to the specifed json file.
  .EXAMPLE
    Export-IMDefinition -Path c:\local\IMDefinitions.json
    Exports all existing Install Manager definitions to the specifed json file.
  .EXAMPLE
    Get-IMDefinition Terminal-Icons | Export-IMDefinition -Path c:\local\Terminal-Icons.json
    Exports the Install Manager definitions for the Terminal-Icons module to the specifed json file.
  .INPUTS
  .OUTPUTS
  .NOTES
  #>
  [CmdletBinding(DefaultParameterSetName = 'All')]
  param (
    #Specify the name (or names) of the Install Manager Definition(s) to export.
    [parameter(Mandatory, ParameterSetName = 'Name')]
    [string[]]$Name
    ,
    #Specify the name (or names) of the Install Manager Definition(s) to export.
    [parameter(ParameterSetName = 'Name')]
    [parameter(ParameterSetName = 'InstallManager', Mandatory)]
    [InstallManager[]]$InstallManager
    ,
    #Specify the file path for the output file. The parent container/directory must already exist.  File format will be json. File will be overwritten if it exists.
    [parameter(Mandatory)]
    [Alias('Path')]
    [ValidateScript( { Test-Path -Path $(Split-Path -path $_ -Parent) -PathType Container })]
    $FilePath
    ,
    #Allows submission of an IMDefinition object via pipeline or named parameter
    [Parameter(ValueFromPipeline, ParameterSetName = 'IMDefinition')]
    [ValidateScript( { $_.psobject.TypeNames[0] -like '*IMDefinition' })]
    [psobject]$IMDefinition
  )

  begin
  {
    if ($PSCmdlet.ParameterSetName -eq 'IMDefinition')
    {
      [System.Collections.Generic.List[object]]$DefsToExport = @()
    }
  }

  process
  {
    switch ($PSCmdlet.ParameterSetName)
    {
      'All'
      {
        Export-PSFConfig -FullName "$($MyInvocation.MyCommand.ModuleName).Definitions.*" -OutPath $FilePath
      }
      'Name'
      {
        @(
          foreach ($n in $Name)
          {
            switch ($InstallManager.count)
            {
              0
              {
                Get-PSFConfig -Module $MyInvocation.MyCommand.ModuleName -Name "Definitions.*.$n"
              }
              Default
              {
                foreach ($im in $InstallManager)
                {
                  Get-PSFConfig -Module $MyInvocation.MyCommand.ModuleName -Name "Definitions.$im.$n"
                }
              }
            }
          }
        ) |
        Export-PSFConfig -OutPath $FilePath
      }
      'InstallManager'
      {
        @(
          foreach ($im in $InstallManager)
          {
            Get-PSFConfig -Module $MyInvocation.MyCommand.ModuleName -Name "Definitions.$im.*"
          }
        ) |
        Export-PSFConfig -OutPath $FilePath
      }
      'IMDefinition'
      {
        foreach ($im in $IMDefinition)
        {
          [void]$DefsToExport.add($(Get-PSFConfig -Module $MyInvocation.MyCommand.ModuleName -Name "Definitions.$($im.InstallManager).$($im.Name)"))
        }
      }
    }
  }
  end
  {
    if ($PSCmdlet.ParameterSetName -eq 'IMDefinition')
    {
      $DefsToExport | Export-PSFConfig -OutPath $FilePath
    }
  }
}
