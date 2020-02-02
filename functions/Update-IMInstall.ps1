function Update-IMInstall
{

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]$Name
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$RequiredVersion
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$AutoUpgrade
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$AutoRemove
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]$ExemptMachine
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [hashtable]$Parameter
        ,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [InstallManager]$InstallManager
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String]$Scope
        #,
        #[Parameter()]
        #[string]$Repository
    )

    begin
    {
        $localmachinename = [System.Environment]::MachineName
    }

    process
    {
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
                    if ($PSBoundParameters.ContainsKey('AdditionalParameter'))
                    {
                        foreach ($key in $AdditionalParameter.keys)
                        {
                            $installModuleParams.$key = $AdditionalParameter.$key
                        }
                    }
                    switch ($true -eq $AutoUpgrade)
                    {
                        $true
                        {
                            if ($false -eq $installedModuleInfo.IsLatestVersion -or $null -eq $installedModuleInfo.IsLatestVersion)
                            {
                                Install-Module @installModuleParams
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
                                Install-Module @installModuleParams
                            }
                        }
                    }
                    if ($true -eq $AutoRemove)
                    {
                        $installedModuleInfo = Get-IMPowerShellGetInstall -Name $Name
                        [System.Collections.ArrayList]$keepVersions = @()
                        $RequiredVersion.split(';').ForEach( { $keepVersions.add($_) }) | Out-Null
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
                            Uninstall-Module @UninstallModuleParams
                        }
                    }
                }
                'chocolatey'
                {
                    $installedModuleInfo = Get-IMChocoInstall -Name $Name
                    $options = ''
                    if ($PSBoundParameters.ContainsKey('AdditionalParameter'))
                    {
                        foreach ($key in $AdditionalParameter.keys)
                        {
                            $options += "--$key"
                            if (-not [string]::IsNullOrWhiteSpace($AdditionalParameter.$key))
                            {
                                $options += "=`"'$AdditionalParameter.$key'`" "
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
            Write-Information -MessageData "$localmachinenanme is in ExemptMachines entry. Skipping Install Definition: $Name"
        }
    }
    end
    {

    }
}