###############################################################################################
# Module Variables
###############################################################################################
$ModuleVariableNames = ('IMConfiguration')
$ModuleVariableNames.ForEach( { Set-Variable -Scope Script -Name $_ -Value $null })
enum InstallManager { Chocolatey; Git; PowerShellGet; Manual }


