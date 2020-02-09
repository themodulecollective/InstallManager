#Requires -Version 5.1
###############################################################################################
# Module Variables
###############################################################################################
$ModuleVariableNames = ('IMConfiguration')
$ModuleVariableNames.ForEach( { Set-Variable -Scope Script -Name $_ -Value $null })
enum InstallManager { Chocolatey; Git; PowerShellGet; Manual }
###############################################################################################
# Module Functions
###############################################################################################
$AllFunctionFiles = (Get-ChildItem -Recurse -File -Filter *.ps1 -Path $(Join-Path -Path $PSScriptRoot -ChildPath 'Functions')).where( {
    $_.BaseName -in @(
      'Export-IMConfiguration'
      'Get-IMChocoInstall'
      'Get-IMPowerShellGetInstall'
      'Get-IMSystemUninstallEntry'
      'Get-IMDefinition'
      'Import-IMModuleConfig'
      'Update-IMInstall'
      'New-IMDefinition'
      'Remove-IMDefinition'
      'Set-IMDefinition'
    )
  })

$AllFunctionFiles.foreach( { . $_.fullname })
###############################################################################################
# Module Removal
###############################################################################################
#Clean up objects that will exist in the Global Scope due to no fault of our own . . . like PSSessions
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove =
{ }
###############################################################################################
# Module Ready for User
###############################################################################################
Import-IMModuleConfig