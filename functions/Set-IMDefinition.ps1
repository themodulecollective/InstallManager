function Set-IMDefinition
{
  <#
  .SYNOPSIS
    Sets an InstallManager Definition and updates the current user's configuration
  .DESCRIPTION
    Sets an InstallManager Definition and updates the current user's configuration
  .EXAMPLE
    PS C:\> Set-IMDefinition -Name textpad -RequiredVersion 8.1.2
    Sets the InstallManager Definition for textpad to require version 8.1.2
  .INPUTS
    None
  .OUTPUTS
    None
  .NOTES

  #>
  [CmdletBinding(SupportsShouldProcess)]
  param (
    # Specify the Name of the Module or Package to set
    [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
    [String]
    $Name
    ,
    # Specify the name of the Install Manager for the Definition to set - usually only necessary in the rare case where you have a name that exists in more then one Install Manager.
    [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
    [InstallManager]
    $InstallManager
    ,
    # Use to Specify one or more required versions for PowerShell Modules or a single version to pin for choco packages
    [parameter(Position = 3)]
    [string[]]$RequiredVersion
    ,
    # Use to specify that InstallManager should automatically install newer versions when update-IMInstall is used with this definition
    [parameter(Position = 4)]
    [bool]$AutoUpgrade
    ,
    # Use to specify that InstallManager should automatically remove older versions when update-IMInstall installs a new version for this definition (for PowerShellGet modules, RequiredVersions are kept)
    [parameter(Position = 5)]
    [bool]$AutoRemove
    ,
    # Use to specify a hashtable of additional parameters required by the Install Manager (PowerShellGet or Chocolatey) when processing this definition. Do NOT Include the leading '-' or '--' when specifying parameter names.
    [parameter(Position = 6)]
    [hashtable]$Parameter
    ,
    # Use to specify machines (by machinename/hostname) that should not process this Install Manager definition
    [parameter(Position = 7)]
    [string[]]$ExemptMachine
    ,
    # Use to Specify the name of the Repository to use for the Definition - like PSGallery, or chocolatey, or chocolatey.licensed
    [parameter(Position = 8)]
    [ValidateNotNullOrEmpty()]
    [string]$Repository
    ,
    # Use to specify the Scope for a PowerShellGet Module
    [parameter(Position = 9)]
    [string]$Scope
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
        $keys = $PSBoundParameters.keys.ForEach( { $_ }) #avoid enumerating and modifying
        foreach ($k in $Keys)
        {
          switch ($k -in ('RequiredVersion', 'AutoUpgrade', 'AutoRemove', 'Parameter', 'ExemptMachine', 'Repository', 'Scope'))
          {
            $true
            {
              if ($PSCmdlet.ShouldProcess("$k = $($PSBoundParameters.$k) on: $($script:ManagedInstalls[$index])"))
              {
                $script:ManagedInstalls[$index].$($k) = $PSBoundParameters.$k
              }
            }
            $false
            { }
          }
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