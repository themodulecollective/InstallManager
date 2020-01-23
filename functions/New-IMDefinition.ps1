function New-IMDefinition
{
  <#
  .SYNOPSIS
    Creates a new Install Manager Definition and stores it in the current user's configuration
  .DESCRIPTION
    Creates a new Install Manager Definition and stores it in the current user's configuration
  .EXAMPLE
    PS C:\> New-IMDefinition -Name sumatrapdf.install -InstallManager Chocolatey
    Adds an Install Manager Definition for the sumatrapdf.install Chocolatey package and sets it to the defaults for Chocolatey
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
    [Parameter(Mandatory, Position = 2)]
    [InstallManager]
    $InstallManager
    ,
    # Use to Specify one or more required versions for PowerShell Modules or a single version to pin for choco packages
    [parameter(Position = 3)]
    [string[]]$RequiredVersion
    ,
    # Use to specify that InstallManager should automatically install newer versions when update-IMInstall is used with this definition
    [parameter(Position = 4)]
    [bool]$AutoUpgrade = $true
    ,
    # Use to specify that InstallManager should automatically remove older versions when update-IMInstall installs a new version for this definition (for PowerShellGet modules, RequiredVersions are kept)
    [parameter(Position = 5)]
    [bool]$AutoRemove = $true
    ,
    # Use to specify any additional parameters required by the Install Manager (PowerShellGet or Chocolatey) when processing this definition
    [parameter(Position = 6)]
    [string[]]$Parameter
    ,
    # Use to specify machines (by machinename/hostname) that should not process this Install Manager definition
    [parameter(Position = 7)]
    [string[]]$ExemptMachine
    ,
    # Use to Specify the name of the Repository to use for the Definition - like PSGallery, or chocolatey, or chocolatey.licensed
    [parameter(Position = 8)]
    [ValidateNotNullOrEmpty()]
    [string]$Repository
  )

  begin
  {

  }
  process
  {
    if ($script:ManagedInstalls.where( { $_.Name -eq $Name -and $_.InstallManager -eq $InstallManager }).count -eq 0)
    {
      [void]$script:ManagedInstalls.Add(
        [pscustomobject]@{
          Name            = $Name
          InstallManager  = $InstallManager -as [String] #avoid an enum serialization warning from Configuration module
          Repository      = if ([string]::IsNullOrWhiteSpace($repository))
          {
            switch ($InstallManager)
            {
              'Chocolatey' { 'Community' }
              'PowerShellGet' { 'PSGallery' }
              Default { '' }
            }
          }
          else { $Repository }
          RequiredVersion = @($RequiredVersion)
          AutoUpgrade     = $AutoUpgrade
          AutoRemove      = $AutoRemove
          Parameter       = @($Parameter)
          ExemptMachine   = @($ExemptMachine)
        }
      )
    }
    else
    {
      throw("Definition for $Name with $InstallManager as the InstallManager already exists. To modify it, use Set-IMDefinition")
    }
    @{Definitions = $script:ManagedInstalls } | Export-Configuration
  }

  end
  {

  }
}