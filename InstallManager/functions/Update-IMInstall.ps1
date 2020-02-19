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
