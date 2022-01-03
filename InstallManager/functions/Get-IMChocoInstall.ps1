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
        Inputs [string]
    .OUTPUTS
        Output [PSCustomObject]
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
                        Invoke-Command -ScriptBlock $([scriptblock]::Create("choco list $n --LocalOnly --LimitOutput --Exact")) | ForEach-Object {
                            $packageName, $installedVersion = $_.split('|')
                            [PSCustomObject]@{
                                Name             = "$packageName"
                                InstalledVersion = $installedVersion
                            }
                        }
                    )
                    $ap = $(
                        Invoke-Command -ScriptBlock $([scriptblock]::Create("choco list $n --LimitOutput --Exact")) | ForEach-Object {
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
                    Invoke-Command -ScriptBlock $([scriptblock]::Create('choco list --LocalOnly --LimitOutput')) | ForEach-Object {
                        $packageName, $installedVersion = $_.split('|')
                        [PSCustomObject]@{
                            Name             = "$packageName"
                            InstalledVersion = $installedVersion
                        }
                    }
                )
                $ChocoOutdatedPackages = @(
                    Invoke-Command -ScriptBlock $([scriptblock]::Create('choco outdated --LimitOutput')) | ForEach-Object {
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
