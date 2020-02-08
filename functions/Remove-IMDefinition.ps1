function Remove-IMDefinition
{
  <#
  .SYNOPSIS
    Removes an Install Manager Definition and updates the current user's configuration
  .DESCRIPTION
    Removes an Install Manager Definition and updates the current user's configuration
  .EXAMPLE
    PS C:\> Remove-IMDefinition -Name textpad -InstallManager Chocolatey
    Removes the Install Manager Definition for the textpad Chocolatey package
  .INPUTS
    None
  .OUTPUTS
    None
  .NOTES

  #>
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Name')]
  param (
    # Specify the Name of the Module or Package
    [Parameter(Mandatory, Position = 1, ParameterSetName = 'Name')]
    [String]
    $Name
    ,
    # Specify the name of the Install Manager to use for the Module (PowerShellGet) or Package (Chocolatey)
    [Parameter(Position = 2, ParameterSetName = 'Name')]
    [InstallManager]
    $InstallManager
    ,
    # Allows submission of an IMDefinition object via pipeline or named parameter
    [Parameter(ValueFromPipeline, ParameterSetName = 'IMDefinition')]
    [ValidateScript( { $_.psobject.TypeNames[0] -eq 'IMDefinition' })]
    [psobject]$IMDefinition
  )

  begin
  {

  }
  process
  {
    switch ($PSCmdlet.ParameterSetName)
    {
      'Name'
      {
        $IMDefinition = $script:ManagedInstalls.where( { $_.Name -eq $Name -and ($_.InstallManager -eq $InstallManager -or $null -eq $InstallManager) })
      }
      'IMDefinition'
      {
        $Name = $IMDefinition.Name
        $InstallManager = $IMDefinition.InstallManager
      }
    }
    switch ($IMDefinition.count)
    {
      1
      {
        $index = $script:ManagedInstalls.FindIndex( { param($d) ($d.name -eq $Name -and ($d.InstallManager -eq $InstallManager -or $null -eq $InstallManager)) })
        if ($PSCmdlet.ShouldProcess("$($script:ManagedInstalls[$index])"))
        {
          $script:ManagedInstalls.RemoveAt($index)
        }
      }
      0
      {
        throw("Not Found: InstallManager Definition for $Name")
      }
      Default
      {
        throw("Ambiguous: InstallManager Definition for $Name.  Try being more specific by specifying the InstallManager.")
      }
    }
    @{Definitions = $script:ManagedInstalls } | Export-Configuration -WarningAction 'SilentlyContinue' #enums being serialized cause a warning
  }

  end
  {

  }
}