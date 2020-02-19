#Requires -Version 5.1
###############################################################################################
# Module Variables
###############################################################################################
$ModuleVariableNames = ('IMConfiguration')
$ModuleVariableNames.ForEach( { Set-Variable -Scope Script -Name $_ -Value $null })
enum InstallManager { Chocolatey; Git; PowerShellGet; Manual }

###############################################################################################
# Module Removal
###############################################################################################
#Clean up objects that will exist in the Global Scope due to no fault of our own . . . like PSSessions

$OnRemoveScript = {
  # perform cleanup
  Write-Verbose -Message 'Removing Module Items from Global Scope'
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript

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

Function Get-IMChocoInstall
{
    <#
    .SYNOPSIS
        Gets an installation information object for all or specified choco packages
    .DESCRIPTION
        Gets an installation information object for all or specified choco packages
    .EXAMPLE
        PS C:\> Get-IMChocoInstall -Name docker-desktop

        Name                    : docker-desktop
        Version                 : 2.2.0.0
        IsLatestVersion         : True
        LatestRepositoryVersion : 2.2.0.0
        LatestVersionInstalled  : True

        Returns an object with information about the installed version of the package, if any, along with information about the latest version available in the repository.

    .EXAMPLE
        PS C:\> Get-IMChocoInstall

        Returns an object with information for each choco installed package, if any, along with information about the latest version available in the repository.  Does not return any information for not installed packages.

    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        # Use to specify the name of the chocolatey package install information to return.  If omitted, returns all available installation information. Accepts installed or not installed package names.
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named', Position = 1)]
        [string[]]$Name
        #,
        #[string]$Repository
        #,
        #[switch]$PerInstalledVersion
    )
    begin
    { }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Named'
            {
                foreach ($n in $Name)
                {
                    $ip = $(
                        Invoke-Command -scriptblock $([scriptblock]::Create("choco list $n --LocalOnly --LimitOutput --Exact")) | ForEach-Object {
                            $packageName, $installedVersion = $_.split('|')
                            [PSCustomObject]@{
                                Name             = "$packageName"
                                InstalledVersion = $installedVersion
                            }
                        }
                    )
                    $ap = $(
                        Invoke-Command -scriptblock $([scriptblock]::Create("choco list $n --LimitOutput --Exact")) | ForEach-Object {
                            $packageName, $availableVersion = $_.split('|')
                            [PSCustomObject]@{
                                Name             = "$packageName"
                                AvailableVersion = $availableVersion
                            }
                        }
                    )
                    [PSCustomObject]@{
                        Name                    = $n
                        Version                 = $ip.InstalledVersion
                        IsLatestVersion         = $ip.InstalledVersion -eq $ap.AvailableVersion
                        #AllInstalledVersions =
                        #Repository
                        #PublishedDate
                        LatestRepositoryVersion = $ap.AvailableVersion
                        #LatestRepositoryVersionPublishedDate
                        LatestVersionInstalled  = $ip.InstalledVersion -eq $ap.AvailableVersion
                    }
                }
            }
        }
    }
    end
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $ChocoInstalledPackages = @(
                    Invoke-Command -scriptblock $([scriptblock]::Create("choco list --LocalOnly --LimitOutput")) | ForEach-Object {
                        $packageName, $installedVersion = $_.split('|')
                        [PSCustomObject]@{
                            Name             = "$packageName"
                            InstalledVersion = $installedVersion
                        }
                    }
                )
                $ChocoOutdatedPackages = @(
                    Invoke-Command -scriptblock $([scriptblock]::Create("choco outdated --LimitOutput")) | ForEach-Object {
                        $packageName, $installedVersion, $latestRepositoryVersion, $pinned = $_.split('|')
                        [PSCustomObject]@{
                            Name                    = "$packageName"
                            InstalledVersion        = $installedVersion
                            LatestRepositoryVersion = $latestRepositoryVersion
                            Pinned                  = switch ($pinned) { 'true' { $true } 'false' { $false } Default { $null } }
                        }
                    }
                )
                $ChocoOutdatedPackagesNames = @($ChocoOutdatedPackages.ForEach( { $_.Name }))
                Foreach ($cip in $ChocoInstalledPackages)
                {
                    if ($ChocoOutdatedPackagesNames -contains $cip.Name)
                    {
                        $cop = $($ChocoOutdatedPackages.Where( { $_.Name -eq $cip.Name }) | Select-Object -First 1)
                        [PSCustomObject]@{
                            Name                    = $cip.Name
                            Version                 = $cip.InstalledVersion
                            IsLatestVersion         = $false
                            #AllInstalledVersions =
                            #Repository
                            #PublishedDate
                            LatestRepositoryVersion = $cop.LatestRepositoryVersion
                            #LatestRepositoryVersionPublishedDate
                            LatestVersionInstalled  = $false
                        }
                    }
                    else
                    {
                        [PSCustomObject]@{
                            Name                    = $cip.Name
                            Version                 = $cip.InstalledVersion
                            IsLatestVersion         = $true
                            #AllInstalledVersions =
                            #Repository
                            #PublishedDate
                            LatestRepositoryVersion = $cip.InstalledVersion
                            #LatestRepositoryVersionPublishedDate
                            LatestVersionInstalled  = $true
                        }
                    }
                }
            }
        }
    }
}

Function Get-IMPowerShellGetInstall
{
    <#
.SYNOPSIS
    Gets an object with information about a Powershell Module, combining information from the module itself (if installed) and PowerShellGet.
.DESCRIPTION
    Gets an object with information about a Powershell Module, combining information from the module itself (if installed) and PowerShellGet.
.EXAMPLE
    PS C:\> Get-IMPowerShellGetInstall -Name Configuration

    Name                                 : Configuration
    Version                              : 1.3.1
    IsLatestVersion                      : True
    AllInstalledVersions                 : {1.3.1}
    InstalledFromRepository              : True
    Repository                           : PSGallery
    InstalledLocation                    : C:\Program Files\PowerShell\Modules\Configuration\1.3.1
    InstalledDate                        : 12/11/2019 5:31:28 PM
    PublishedDate                        : 7/12/2018 4:45:53 AM
    LatestRepositoryVersion              : 1.3.1
    LatestRepositoryVersionPublishedDate : 7/12/2018 4:45:53 AM
    LatestVersionInstalled               : True

    Gets an object with information about the Configuration module, a module that was installed with PowerShellGet module
.EXAMPLE
    Get-IMPowerShellGetInstall pscloudflare

    Name                                 : pscloudflare
    Version                              : 0.0.8
    IsLatestVersion                      : False
    AllInstalledVersions                 : {0.0.5, 0.0.4, 0.0.8}
    InstalledFromRepository              : False
    Repository                           :
    InstalledLocation                    : ...\GitRepos\PSModules\PSCloudflare
    InstalledDate                        :
    PublishedDate                        :
    LatestRepositoryVersion              : 0.0.7
    LatestRepositoryVersionPublishedDate : 1/11/2018 7:25:53 PM
    LatestVersionInstalled               :

    Gets an object with information about the PSCloudflare module, a module that has multiple versions installed and also has a version from a local git repository.
.EXAMPLE

    Get-IMPowerShellGetInstall pscloudflare -PerInstalledVersion

    Name                                 : pscloudflare
    Version                              : 0.0.5
    IsLatestVersion                      : False
    AllInstalledVersions                 : {0.0.5, 0.0.4, 0.0.8}
    InstalledFromRepository              : True
    Repository                           : PSGallery
    InstalledLocation                    : C:\Program Files\PowerShell\Modules\PSCloudFlare\0.0.5
    InstalledDate                        : 1/22/2020 8:04:27 PM
    PublishedDate                        : 12/14/2017 4:00:44 AM
    LatestRepositoryVersion              : 0.0.7
    LatestRepositoryVersionPublishedDate : 1/11/2018 7:25:53 PM
    LatestVersionInstalled               : False

    Name                                 : pscloudflare
    Version                              : 0.0.4
    IsLatestVersion                      : False
    AllInstalledVersions                 : {0.0.5, 0.0.4, 0.0.8}
    InstalledFromRepository              : True
    Repository                           : PSGallery
    InstalledLocation                    : C:\Program Files\PowerShell\Modules\PSCloudFlare\0.0.4
    InstalledDate                        : 1/22/2020 8:04:24 PM
    PublishedDate                        : 12/22/2016 6:02:37 PM
    LatestRepositoryVersion              : 0.0.7
    LatestRepositoryVersionPublishedDate : 1/11/2018 7:25:53 PM
    LatestVersionInstalled               : False

    Name                                 : pscloudflare
    Version                              : 0.0.8
    IsLatestVersion                      : False
    AllInstalledVersions                 : {0.0.5, 0.0.4, 0.0.8}
    InstalledFromRepository              : False
    Repository                           :
    InstalledLocation                    : C:\Users\MikeCampbell\GitRepos\PSModules\PSCloudflare
    InstalledDate                        :
    PublishedDate                        :
    LatestRepositoryVersion              : 0.0.7
    LatestRepositoryVersionPublishedDate : 1/11/2018 7:25:53 PM
    LatestVersionInstalled               :

    Gets an object with information about each installed version the PSCloudFlare module, a module that has multiple versions installed and also has a version from a local git repository.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        # Use to specify the name of one or more modules for which to get installation information
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named', Position = 1)]
        [string[]]$Name
        ,
        # use to specify an alternative repository.  The repository should already be registered on the system.
        [string]$Repository
        ,
        # use to get an object per installed version of the specified module(s)
        [switch]$PerInstalledVersion
    )
    begin
    {
        [System.Collections.ArrayList]$LocalModules = @()
        [System.Collections.ArrayList]$LocalPowerShellGetModules = @()
        [System.Collections.ArrayList]$LatestRepositoryModules = @()
        [System.Collections.ArrayList]$NamedModules = @()
        [System.Collections.ArrayList]$RepoFoundModules = @()
        $FindModuleParams = @{
            ErrorAction = 'SilentlyContinue'
        }
        if ($PSBoundParameters.ContainsKey('Repository'))
        {
            $FindModuleParams.Repository = $PSBoundParameters.Repository
        }
        $GetInstalledModuleParams = @{
            ErrorAction = 'SilentlyContinue'
        }
    }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                #Get the locally available modules on this system for the current user based on entries in $env:Psmodulepath
                @(Get-Module -ListAvailable).foreach( { $LocalModules.add($_) | Out-Null })
                #Get the locally available modules that were installed using PowerShellGet Module commands
                $LocalModules.where( { $null -ne $_.RepositorySourceLocation }).foreach( { Get-InstalledModule -Name $_.Name -RequiredVersion $_.Version @GetInstalledModuleParams }).foreach( { $LocalPowerShellGetModules.add($_) | Out-Null })
                ($LocalModules.ForEach( { $_.Name }) | Sort-Object -Unique).foreach( { $NamedModules.add([pscustomobject]@{Name = $_ }) | Out-Null })
                $LocalPowerShellGetModules.ForEach( {
                        if (-not $RepoFoundModules.Contains($_.name))
                        {
                            $FindModuleParams.Name = $_.name
                            $RepositoryModule = Find-Module @FindModuleParams
                            $LatestRepositoryModules.add($RepositoryModule) | Out-Null
                            $RepoFoundModules.add($_.name) | Out-Null
                        }
                    })
            }
            'Named'
            {
                foreach ($n in $Name)
                {
                    #Get the locally available named module(s) on this system for the current user based on entries in $env:Psmodulepath
                    $LocalModules.add($(Get-Module -ListAvailable -Name $n -ErrorAction Stop)) | Out-Null
                    #Get the locally available named module(s) that were installed using PowerShellGet Module commands
                    $GetInstalledModuleParams.Name = $n
                    $GetInstalledModuleParams.AllVersions = $true
                    $LocalPowerShellGetModules.add($(Get-InstalledModule @GetInstalledModuleParams)) | Out-Null
                    #Get the PSGallery Module for the named module
                    $FindModuleParams.Name = $n
                    $LatestRepositoryModule = Find-Module @FindModuleParams
                    $LatestRepositoryModules.add($LatestRepositoryModule) | Out-Null
                    $NamedModules.add($([pscustomobject]@{Name = $n })) | Out-Null
                }
            }
        }
    }
    End
    {
        $LocalModulesLookupNV = @{ }
        $LocalModules.foreach( { $_ }) | Select-Object -Property Name, Version, Path, GUID, ModuleBase, LicenseUri, ProjectUri, @{n = 'NameVersion'; e = { [string]$($_.Name + $_.Version) } } | ForEach-Object -Process { $LocalModulesLookupNV.$($_.NameVersion) = $_ }
        #$LocalModulesLookupN = $LocalModules.foreach({$_}) | Select-Object -Property Name,Version,Path,GUID,ModuleBase,LicenseUri,ProjectUri,@{n='NameVersion';e={$_.Name + $_.Version}} | Group-Object -AsHashTable -Property Name
        $LocalPowerShellGetModulesLookup = @{ }
        $LocalPowerShellGetModules.foreach( { $_ }) | Select-Object -Property Name, Version, Author, PublishedDate, InstalledDate, UpdatedDate, LicenseUri, InstalledLocation, Repository, @{n = 'NameVersion'; e = { $_.Name + $_.Version } } | ForEach-Object -Process { $LocalPowerShellGetModulesLookup.$($_.NameVersion) = $_ }
        $LatestRepositoryModulesLookup = @{ }
        $LatestRepositoryModules.foreach( { $_ }) | Select-Object -Property Name, Version, Author, PublishedDate, LicenseUri, ProjectUri, Repository | ForEach-Object -Process { $LatestRepositoryModulesLookup.$($_.Name) = $_ }
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $PerInstalledVersionOutput = @(
                    foreach ($lm in $LocalModules.foreach( { $_ }))
                    {
                        $lookup = $lm.Name + $lm.Version
                        [PSCustomObject]@{
                            Name                                 = $lm.Name
                            Version                              = $lm.Version
                            IsLatestVersion                      = if ($null -ne $LatestRepositoryModulesLookup.$($lm.name).Version) { $lm.version -eq $LatestRepositoryModulesLookup.$($lm.name).Version } else { $null }
                            AllInstalledVersions                 = @($LocalModules.foreach( { $_ }).where( { $_.Name -ieq $lm.Name }).foreach( { $_.Version.tostring() }))
                            InstalledFromRepository              = $null -ne $lm.RepositorySourceLocation
                            Repository                           = $LocalPowerShellGetModulesLookup.$lookup.Repository
                            InstalledLocation                    = $lm.ModuleBase
                            InstalledDate                        = $LocalPowerShellGetModulesLookup.$lookup.InstalledDate
                            PublishedDate                        = $LocalPowerShellGetModulesLookup.$lookup.PublishedDate
                            LatestRepositoryVersion              = $LatestRepositoryModulesLookup.$($lm.name).Version
                            LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$($lm.name).PublishedDate
                            LatestVersionInstalled               = if ($null -eq $lm.RepositorySourceLocation) { $null } else { $LocalModulesLookupNV.ContainsKey($lm.Name + $LatestRepositoryModulesLookup.$($lm.name).Version.tostring()) }
                        }
                    }
                )
            }
            'Named'
            {
                $PerInstalledVersionOutput = @(
                    foreach ($nm in $NamedModules)
                    {
                        if ($LocalModules.foreach( { $_ }).where( { $_.Name -ieq $nm.Name }).count -ge 1)
                        {
                            foreach ($lm in $LocalModules.foreach( { $_ }).where( { $_.Name -ieq $nm.Name }))
                            {
                                $lookup = $nm.Name + $lm.Version
                                [PSCustomObject]@{
                                    Name                                 = $nm.Name
                                    Version                              = $lm.Version
                                    IsLatestVersion                      = if ($null -ne $LatestRepositoryModulesLookup.$($nm.name).Version) { $lm.version -eq $LatestRepositoryModulesLookup.$($nm.name).Version } else { $null }
                                    AllInstalledVersions                 = @($LocalModules.foreach( { $_ }).where( { $_.Name -ieq $nm.Name }).foreach( { $_.Version }))
                                    InstalledFromRepository              = $null -ne $lm.RepositorySourceLocation
                                    Repository                           = $LocalPowerShellGetModulesLookup.$lookup.Repository
                                    InstalledLocation                    = $lm.ModuleBase
                                    InstalledDate                        = $LocalPowerShellGetModulesLookup.$lookup.InstalledDate
                                    PublishedDate                        = $LocalPowerShellGetModulesLookup.$lookup.PublishedDate
                                    LatestRepositoryVersion              = $LatestRepositoryModulesLookup.$($nm.name).Version
                                    LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$($nm.name).PublishedDate
                                    LatestVersionInstalled               = if ($null -eq $lm.RepositorySourceLocation) { $null } else { $LocalModulesLookupNV.ContainsKey($lm.Name + $LatestRepositoryModulesLookup.$($lm.name).Version.tostring()) }
                                    #LatestVersionInstalled = $LocalModulesLookupNV.ContainsKey($nm.Name + $LatestRepositoryModulesLookup.$($nm.name).Version.tostring())
                                }
                            }
                        }
                        else
                        {
                            $lookup = $nm.Name
                            [PSCustomObject]@{
                                Name                                 = $lookup
                                Version                              = $null
                                IsLatestVersion                      = $null
                                AllInstalledVersions                 = $null
                                InstalledFromRepository              = $null
                                Repository                           = $LatestRepositoryModulesLookup.$lookup.Repository
                                InstalledLocation                    = $null
                                InstalledDate                        = $null
                                PublishedDate                        = $null
                                LatestRepositoryVersion              = $LatestRepositoryModulesLookup.$lookup.Version
                                LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$lookup.PublishedDate
                                LatestVersionInstalled               = $false
                            }
                        }
                    }
                )
            }
        }
        switch ($PerInstalledVersion)
        {
            $true
            {
                $PerInstalledVersionOutput
            }
            $false
            {
                $PerModuleGroups = $PerInstalledVersionOutput | Group-Object -Property Name
                foreach ($pmg in $PerModuleGroups)
                {
                    $lvInstalled = $pmg.Group.Version.foreach( { $_.tostring() }) | Sort-Object -Descending | Select-Object -first 1
                    switch ($null -eq $lvInstalled)
                    {
                        $false
                        {
                            [PSCustomObject]@{
                                Name                                 = $pmg.Name
                                Version                              = $lvInstalled
                                IsLatestVersion                      = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).IsLatestVersion | Select-Object -Unique
                                AllInstalledVersions                 = @($pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).AllInstalledVersions | Select-Object -Unique)
                                InstalledFromRepository              = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).InstalledFromRepository | Select-Object -Unique
                                Repository                           = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).Repository | Select-Object -Unique
                                InstalledLocation                    = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).InstalledLocation
                                InstalledDate                        = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).InstalledDate | Select-Object -Unique
                                PublishedDate                        = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).PublishedDate | Select-Object -Unique
                                LatestRepositoryVersion              = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).LatestRepositoryVersion | Select-Object -Unique
                                LatestRepositoryVersionPublishedDate = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).LatestRepositoryVersionPublishedDate | Select-Object -Unique
                                LatestVersionInstalled               = $pmg.Group.where( { $_.version.tostring() -eq $lvInstalled }).LatestVersionInstalled | Select-Object -Unique
                            }
                        }
                        $true
                        {
                            [PSCustomObject]@{
                                Name                                 = $pmg.Name
                                Version                              = $null
                                IsLatestVersion                      = $null
                                AllInstalledVersions                 = $null
                                InstalledFromRepository              = $null
                                Repository                           = $LatestRepositoryModulesLookup.$($pmg.Name).Repository
                                InstalledLocation                    = $null
                                InstalledDate                        = $null
                                PublishedDate                        = $null
                                LatestRepositoryVersion              = $LatestRepositoryModulesLookup.$($pmg.Name).Version
                                LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$($pmg.Name).PublishedDate
                                LatestVersionInstalled               = $False
                            }
                        }
                    }
                }
            }
        }
    }
}

Function Get-IMSystemUninstallEntry
{
    <#
.SYNOPSIS
    Gets all uninstall entries from the windows registry
.DESCRIPTION
    Gets all uninstall entries from the windows registry
.EXAMPLE
    PS C:\> Get-IMSystemUninstallEntry
    Gets a powershell object with a specified set of properties for each uninstall entry found in the windows registry.  Change the set of properties with the SpecifiedProperties parameter.
.EXAMPLE
    PS C:\> Get-IMSystemUninstallEntry -raw
    Gets a powershell object with all available properties for each uninstall entry found in the windows registry
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [cmdletbinding(DefaultParameterSetName = 'SpecifiedProperties')]
    param(
        # Use to return all available properties for each uninstall entry
        [parameter(ParameterSetName = 'Raw')]
        [switch]$Raw
        ,
        # Use to override the default set of properties included with the uninstall entry output objects
        [parameter(ParameterSetName = 'SpecifiedProperties')]
        [string[]]$Property = @('DisplayName', 'DisplayVersion', 'InstallDate', 'Publisher')
    )
    # paths: x86 and x64 registry keys are different
    if ([IntPtr]::Size -eq 4)
    {
        $path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else
    {
        $path = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    $UninstallEntries = Get-ItemProperty $path
    # use only with name and unistall information
    #.{process{ if ($_.DisplayName -and $_.UninstallString) { $_ } }} |
    # select more or less common subset of properties
    #Select-Object DisplayName, Publisher, InstallDate, DisplayVersion, HelpLink, UninstallString |
    # and finally sort by name
    #Sort-Object DisplayName
    if ($Raw) { $UninstallEntries | Sort-Object -Property DisplayName }
    else
    {
        $UninstallEntries | Sort-Object -Property DisplayName | Select-Object -Property $Property
    }

}

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

function Import-IMConfiguration
{
    $script:IMConfiguration = Get-PSFConfigValue -FullName "$($MyInvocation.MyCommand.ModuleName).Preferences"
}

function Update-IMInstall
{
    <#
    .SYNOPSIS
        Processes an IMDefinition to install, update, or remove (future) the associated package, module, or repo (future)
    .DESCRIPTION
        Processes an IMDefinition to install, update, or remove (future) the associated package, module, or repo (future)
    .EXAMPLE
        Set-IMDefinition -Name rufus -InstallManager Chocolatey
        Get-IMDefinition -Name rufus | Update-IMinstall
        processes the newly created IMDefinition for the rufus package and installs or updates the package as appropriate
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'IMDefinition')]
    param (
        #Allows submission of an IMDefinition object via pipeline or named parameter
        [Parameter(ValueFromPipeline, ParameterSetName = 'IMDefinition')]
        [ValidateScript( { $_.psobject.TypeNames[0] -like '*IMDefinition' })]
        [psobject]$IMDefinition
        ,
        # Specify the Name of the Module or Package for which to update the Install
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [string[]]$Name
        ,
        # Specify the name of the Install Manager for the Definition to Install - usually only necessary in the rare case where you have a name that exists in more then one Install Manager.
        [Parameter(Position = 2, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [InstallManager]
        $InstallManager
    )

    begin
    {
        $localmachinename = [System.Environment]::MachineName
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'IMDefinition'
            { }

            'Name'
            {
                $IMDefinition = @(Get-IMDefinition -Name $Name -InstallManager $InstallManager)
            }
        }
        foreach ($imd in $IMDefinition)
        {
            $InstallManager = $imd.InstallManager
            $Name = $imd.Name
            $RequiredVersion = $imd.RequiredVersion
            $AutoUpgrade = $imd.AutoUpgrade
            $AutoRemove = $imd.AutoRemove
            $ExemptMachine = $imd.ExemptMachine
            $Parameter = $imd.Parameter
            $Scope = $imd.Scope
            if ($localmachinename -notin $ExemptMachine)
            {

                Write-Information -MessageData "Using $InstallManager to Process Install Definition: $Name"
                switch ($InstallManager)
                {
                    'PowerShellGet'
                    {
                        $installedModuleInfo = Get-IMPowerShellGetInstall -Name $Name
                        $installModuleParams = @{
                            Name          = $Name
                            Scope         = switch ([string]::IsNullOrWhiteSpace($Scope)) { $true { 'CurrentUser' } $false { $Scope } }
                            Force         = $true
                            AcceptLicense = $true
                            AllowClobber  = $true
                        }
                        if ($Parameter.count -ge 1)
                        {
                            foreach ($key in $Parameter.keys)
                            {
                                $installModuleParams.$key = $Parameter.$key
                            }
                        }
                        switch ($true -eq $AutoUpgrade)
                        {
                            $true
                            {
                                if ($false -eq $installedModuleInfo.IsLatestVersion -or $null -eq $installedModuleInfo.IsLatestVersion)
                                {
                                    if ($PSCmdlet.ShouldProcess("Install-Module " + $($installModuleParams.GetEnumerator().foreach( { '-' + $_.Name + ' ' + $_.Value }) -join ' ')))
                                    {
                                        Install-Module @installModuleParams
                                    }
                                }
                            }
                            $false
                            {
                                #notification/logging that a new version is available
                            }
                        }
                        if (-not [string]::IsNullOrEmpty($RequiredVersion))
                        {
                            $installedModuleInfo = Get-IMPowerShellGetInstall -Name $Name
                            foreach ($rv in $RequiredVersion)
                            {
                                if ($rv -notin $installedModuleInfo.AllInstalledVersions)
                                {
                                    $installModuleParams.RequiredVersion = $rv
                                    if ($PSCmdlet.ShouldProcess("Install-Module " + $($installModuleParams.GetEnumerator().foreach( { '-' + $_.Name + ' ' + $_.Value }) -join ' ')))
                                    {
                                        Install-Module @installModuleParams
                                    }
                                }
                            }
                        }
                        if ($true -eq $AutoRemove)
                        {
                            $installedModuleInfo = Get-IMPowerShellGetInstall -Name $Name
                            [System.Collections.ArrayList]$keepVersions = @()
                            $RequiredVersion.ForEach( { $keepVersions.add($_) }) | Out-Null
                            if ($true -eq $autoupgrade)
                            {
                                $keepVersions.add($installedModuleInfo.LatestRepositoryVersion) | Out-Null
                            }
                            $removeVersions = @($installedModuleInfo.AllInstalledVersions | Where-Object -FilterScript { $_ -notin $keepVersions })
                            if ($removeVersions.Count -ge 1)
                            {
                                $UninstallModuleParams = @{
                                    Name  = $Name
                                    Force = $true
                                }
                            }
                            foreach ($rV in $removeVersions)
                            {
                                $UninstallModuleParams.RequiredVersion = $rV
                                if ($PSCmdlet.ShouldProcess("Uninstall-Module " + $($uninstallModuleParams.GetEnumerator().foreach( { '-' + $_.Name + ' ' + $_.Value }) -join ' ')))
                                {
                                    Uninstall-Module @UninstallModuleParams
                                }
                            }
                        }
                    }
                    'chocolatey'
                    {
                        $installedModuleInfo = Get-IMChocoInstall -Name $Name
                        $options = ''
                        if ($Parameter.count -ge 1)
                        {
                            foreach ($key in $Parameter.keys)
                            {
                                $options += "--$key"
                                if (-not [string]::IsNullOrWhiteSpace($Parameter.$key))
                                {
                                    $options += "=`"'$Parameter.$key'`" "
                                }
                                else
                                {
                                    $options += ' '
                                }
                            }
                        }
                        switch ($true -eq $AutoUpgrade)
                        {
                            $true
                            {
                                if ($false -eq $installedModuleInfo.IsLatestVersion -or $null -eq $installedModuleInfo.IsLatestVersion)
                                {
                                    Write-Information -MessageData "Running Command: 'choco upgrade $Name --Yes --LimitOutput $options'"
                                    if ($PSCmdlet.ShouldProcess("choco upgrade $Name --Yes --LimitOutput $options"))
                                    {
                                        Invoke-Command -ScriptBlock $([scriptblock]::Create("choco upgrade $Name --Yes --LimitOutput $options"))
                                    }
                                }
                            }
                            $false
                            {
                                if ($null -eq $installedModuleInfo)
                                {
                                    Write-Information -MessageData "Running Command: 'choco upgrade $Name --Yes --LimitOutput $options'"
                                    if ($PSCmdlet.ShouldProcess("choco upgrade $Name --Yes --LimitOutput $options"))
                                    {
                                        Invoke-Command -ScriptBlock $([scriptblock]::Create("choco upgrade $Name --Yes --LimitOutput $options"))
                                    }
                                }
                                #notification/logging that a new version is available
                            }
                        }
                    }
                }
            }
            else
            {
                Write-Information -MessageData "$localmachinename is present in ExemptMachines for Install Definition $Name"
            }
        }
    }
    end
    { }
}

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
  [CmdletBinding(SupportsShouldProcess)]
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
    # Use to specify a hashtable of additional parameters required by the Install Manager (PowerShellGet or Chocolatey) when processing this definition. Do NOT Include the leading '-' or '--' when specifying parameter names. For Chocolatey options that require no value, use $null.  For PowerShellGet params such as bool or switch, use $true or $false as the value.
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
    if ((Get-IMDefinition -Name $Name -InstallManager $InstallManager).count -eq 0)
    {
      $Definition =
      [pscustomobject]@{
        PSTypeName      = 'IMDefinition'
        Name            = $Name
        InstallManager  = $InstallManager -as [String] #avoid an enum serialization warning from Configuration module
        Repository      = if ([string]::IsNullOrWhiteSpace($repository))
        {
          switch ($InstallManager)
          {
            #'Chocolatey' { '' }
            'PowerShellGet' { 'PSGallery' }
            Default { '' }
          }
        }
        else { $Repository }
        RequiredVersion = switch ($PSBoundParameters.ContainsKey('RequiredVersion')) { $true { $RequiredVersion } $false { @() } }
        AutoUpgrade     = $AutoUpgrade
        AutoRemove      = $AutoRemove
        Parameter       = switch ($PSBoundParameters.ContainsKey('Parameter')) { $true { $Parameter } $false { @{ } } }
        ExemptMachine   = switch ($PSBoundParameters.ContainsKey('ExemptMachine')) { $true { $ExemptMachine } $false { @() } }
        Scope           = $Scope
      }
      if ($PSCmdlet.ShouldProcess("$Definition"))
      {
        $SetConfigParams = @{
          Module      = $MyInvocation.MyCommand.ModuleName
          AllowDelete = $true
          Passthru    = $true
          Name        = "Definitions.$Installmanager.$Name"
          Value       = $Definition
        }
        Set-PSFConfig @SetConfigParams | Register-PSFConfig
      }
    }
    else
    {
      throw("Definition for $Name with $InstallManager as the InstallManager already exists. To modify it, use Set-IMDefinition")
    }
  }

  end
  {

  }
}

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

###############################################################################################
# Module Ready for User
###############################################################################################
Import-IMConfiguration
