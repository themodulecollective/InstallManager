Function Get-IMWinGetInstall
{
    <#
    .SYNOPSIS
        Gets an installation information object for all or specified WinGet packages
    .DESCRIPTION
        Gets an installation information object for all or specified WinGet packages
    .EXAMPLE
        PS C:\> Get-IMWinGetInstall -Name docker-desktop

        Name                    : docker-desktop
        Version                 : 2.2.0.0
        IsLatestVersion         : True
        LatestRepositoryVersion : 2.2.0.0
        LatestVersionInstalled  : True

        Returns an object with information about the installed version of the package, if any, along with information about the latest version available in the repository.

    .EXAMPLE
        PS C:\> Get-IMWinGetInstall

        Returns an object with information for each WinGet installed package, if any, along with information about the latest version available in the repository.  Does not return any information for not installed packages.

    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        # Use to specify the name of the WinGet package install information to return.  If omitted, returns all available installation information. Accepts installed or not installed package names.
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
                    #list the installed package
                    $rawLines = @(Invoke-Command -ScriptBlock $([scriptblock]::Create("winget list $n --exact --count 1")) |
                        Out-String -Stream)
                    switch ($rawLines[2])
                    {
                        'No installed package found matching input criteria.'
                        {
                            #show the package information from repo
                            $rawLine = Invoke-Command -ScriptBlock $([scriptblock]::Create("winget show $n --exact")) |
                            Select-String -Pattern 'Version:\s[\d]'
                            $aVersionStart = $rawLine.tostring().IndexOf(':') + 1
                            $ap = [PSCustomObject]@{
                                Name             = $Id
                                AvailableVersion = $rawLine.tostring().Substring($aVersionStart).Trim()
                            }

                            [PSCustomObject]@{
                                Name                    = $n
                                Version                 = $null
                                IsLatestVersion         = $false
                                LatestRepositoryVersion = $ap.AvailableVersion
                                LatestVersionInstalled  = $false
                            }
                        }
                        default
                        {
                            $header = $rawLines[2]
                            $row = $rawLines[4]
                            $IdStart = $header.IndexOf('Id')
                            $VersionStart = $header.IndexOf('Version')
                            $SourceStart = $header.IndexOf('Source')
                            $Id = $row.Substring($idStart, $versionStart - $idStart).Trim()
                            $Version = $row.Substring($versionStart, $SourceStart - $versionStart).Trim()
                            #$Source = $line.Substring($SourceStart, $VersionStartStart - $SourceStart).TrimEnd()
                            $ip = [PSCustomObject]@{
                                Name             = $Id
                                InstalledVersion = $Version
                            }
                            #show the package information from repo
                            $rawLine = Invoke-Command -ScriptBlock $([scriptblock]::Create("winget show $Id --Exact")) |
                            Select-String -Pattern 'Version:\s[\d]'
                            $aVersionStart = $rawLine.tostring().IndexOf(':') + 1
                            $ap = [PSCustomObject]@{
                                Name             = $Id
                                AvailableVersion = $rawLine.tostring().Substring($aVersionStart).Trim()
                            }
                            [PSCustomObject]@{
                                Name                    = $Id
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
        }
    }
    end
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $rawLines = @(Invoke-Command -ScriptBlock $([scriptblock]::Create('winget list')) | Out-String -Stream | Select-String -Pattern 'Version\s+Source|\s+winget')
                $rawLines
                $header = $rawLines[0].tostring()
                $rows = @($rawLines[1..$($rawLines.Count -1)].foreach({$_.tostring()}))
                $IdStart = $header.IndexOf('Id')
                $VersionStart = $header.IndexOf('Version')
                $SourceStart = $header.IndexOf('Source')
                $WingetInstalledPackages = @(
                    foreach ($r in $rows)
                    {
                        #$n = $r.substring(0,$IdStart).TrimEnd()
                        $Id = $r.Substring($idStart, $versionStart - $idStart).Trim()
                        $Version = $r.Substring($versionStart, $SourceStart - $versionStart).Trim()
                        [PSCustomObject]@{
                            Name             = $Id
                            InstalledVersion = $Version
                        }
                    }
                )
                foreach ($wip in $WingetInstalledPackages)
                {
                    $rawLine = Invoke-Command -ScriptBlock $([scriptblock]::Create("winget show $($wip.name) --Exact")) |
                    Out-String -Stream | Select-String -Pattern 'Version:\s[\d]'
                    $aVersionStart = $rawLine.tostring().IndexOf(':') + 1
                    $availableVersion = $rawLine.tostring().Substring($aVersionStart).Trim()
                    [PSCustomObject]@{
                        Name                    = $wip.Name
                        Version                 = $wip.InstalledVersion
                        IsLatestVersion         = $wip.InstalledVersion -eq $availableVersion
                        LatestRepositoryVersion = $availableVersion
                        LatestVersionInstalled  = $wip.InstalledVersion -eq $availableVersion
                    }
                }
            }
        }
    }
}
