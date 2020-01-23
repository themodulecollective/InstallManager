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
  [CmdletBinding()]
  param (
    # Specify the Name of the Module or Package
    [Parameter(Mandatory, Position = 1)]
    [String]
    $Name
    ,
    # Specify the name of the Install Manager to use for the Module (PowerShellGet) or Package (Chocolatey)
    [Parameter(Position = 2)]
    [InstallManager]
    $InstallManager
  )

  begin
  {

  }
  process
  {
    $Definition = $script:ManagedInstalls.where( { $_.Name -eq $Name -and ($_.InstallManager -eq $InstallManager -or $null -eq $InstallManager) })
    switch ($Definition.count)
    {
      1
      {
        $index = $script:ManagedInstalls.FindIndex( { param($d) ($d.name -eq $Name -and ($d.InstallManager -eq $InstallManager -or $null -eq $InstallManager)) })
        $script:ManagedInstalls.RemoveAt($index)
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