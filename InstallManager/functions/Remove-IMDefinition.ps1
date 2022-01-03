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
    # Specify the name of the Install Manager to use for the Module (PowerShellGet) or Package (WinGet or Chocolatey)
    [Parameter(Position = 2, ParameterSetName = 'Name')]
    [InstallManager]
    $InstallManager
    ,
    # Allows submission of an IMDefinition object via pipeline or named parameter
    [Parameter(ValueFromPipeline, ParameterSetName = 'IMDefinition')]
    [ValidateScript( { $_.psobject.TypeNames[0] -like '*IMDefinition' })]
    $IMDefinition
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
            #All OK - found just one Definition to Remove
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
      $remConfigParams = @{
        Module = $MyInvocation.MyCommand.ModuleName
        Name   = "Definitions.$($imd.InstallManager).$($imd.Name)"
      }
      if ($PSCmdlet.ShouldProcess("Name = $($imd.Name); InstallManager = $($imd.InstallManager)"))
      {
        Set-PSFConfig @remConfigParams -AllowDelete
        $remConfigParams.Confirm = $false
        Remove-PSFConfig @remConfigParams
      }
    }
  }

  end
  {

  }
}
