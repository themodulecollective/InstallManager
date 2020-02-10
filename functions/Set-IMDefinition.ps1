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
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Name')]
  param (
    # Specify the Name of the Module or Package for which to set the IMDefintion
    [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
    [String]
    $Name
    ,
    # Specify the name of the Install Manager for the Definition to set - usually only necessary in the rare case where you have a name that exists in more then one Install Manager.
    [Parameter(Position = 2, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
    [InstallManager]
    $InstallManager
    ,
    #Allows submission of an IMDefinition object via pipeline or named parameter
    [Parameter(ValueFromPipeline, ParameterSetName = 'IMDefinition')]
    [ValidateScript( { $_.psobject.TypeNames[0] -like '*IMDefinition' })]
    [psobject]$IMDefinition
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
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope
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
        $IMDefinition = @(Get-IMDefinition -Name $Name -InstallManager $InstallManager)
        switch ($IMDefinition.count)
        {
          0
          {
            Write-Warning -Message "Not Found: InstallManager Definition for $Name"
            Return
          }
          1
          {
            #All OK - found just one Definition to Set
          }
          Default
          {
            throw("Ambiguous: InstallManager Definition for $Name.  Try being more specific by specifying the InstallManager.")
          }
        }
      }
    }

    foreach ($imd in $IMDefinition)
    {
      $keys = $PSBoundParameters.keys.ForEach( { $_ }) #avoid enumerating and modifying
      foreach ($k in $keys)
      {
        switch ($k -in ('RequiredVersion', 'AutoUpgrade', 'AutoRemove', 'Parameter', 'ExemptMachine', 'Repository', 'Scope'))
        {
          $true
          {
              $imd.$k = $PSBoundParameters.$k
          }
          $false
          { }
        }
      }
      if ($PSCmdlet.ShouldProcess("$imd"))
      {
        $SetConfigParams = @{
          Module      = $MyInvocation.MyCommand.ModuleName
          AllowDelete = $true
          Passthru    = $true
          Name        = "Definitions.$($imd.InstallManager).$($imd.Name)"
          Value       = $imd
        }
        Set-PSFConfig @SetConfigParams | Register-PSFConfig
      }
    }
  }

  end
  {

  }
}