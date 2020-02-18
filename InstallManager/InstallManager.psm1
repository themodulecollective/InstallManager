#Requires -Version 5.1

$ModuleName = $MyInvocation.MyCommand.Name.Replace(".psm1", "")
#Write-Information -MessageData "Module Name is $ModuleName" -InformationAction Continue
$ModuleManifest = Join-Path -Path $PSScriptRoot -ChildPath $($Script:ModuleName + '.psd1')
#Write-Information -MessageData "Module Manifest is $ModuleManifest" -InformationAction Continue
$ModuleFunctionFiles = @(
  'Export-IMDefinition'
  'Get-IMChocoInstall'
  'Get-IMPowerShellGetInstall'
  'Get-IMSystemUninstallEntry'
  'Get-IMDefinition'
  'Import-IMDefinition'
  'Import-IMConfiguration'
  'Update-IMInstall'
  'New-IMDefinition'
  'Remove-IMDefinition'
  'Set-IMDefinition'
)

. $PSScriptRoot\scripts\BeginImport.ps1
. $PSScriptRoot\scripts\LoadFunctions.ps1
. $PSScriptRoot\scripts\AtRemoval.ps1
. $PSScriptRoot\scripts\EndImport.ps1
