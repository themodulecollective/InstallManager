#Requires -Version 5.1

$ModuleFolder = Split-Path $PSCommandPath -Parent

$Scripts = Join-Path -Path $ModuleFolder -ChildPath 'scripts'
$Functions = Join-Path -Path $ModuleFolder -ChildPath 'functions'

#Write-Information -MessageData "Scripts Path  = $Scripts" -InformationAction Continue
#Write-Information -MessageData "Functions Path  = $Functions" -InformationAction Continue

$Script:ModuleFiles = @(
  $(Join-Path -Path $Scripts -ChildPath 'Initialize.ps1')
  # Load Functions
  $(Join-Path -Path $functions -ChildPath 'Export-IMDefinition.ps1')
  $(Join-Path -Path $functions -ChildPath 'Get-IMChocoInstall.ps1')
  $(Join-Path -Path $functions -ChildPath 'Get-IMPowerShellGetInstall.ps1')
  $(Join-Path -Path $functions -ChildPath 'Get-IMSystemUninstallEntry.ps1')
  $(Join-Path -Path $functions -ChildPath 'Get-IMDefinition.ps1')
  $(Join-Path -Path $functions -ChildPath 'Import-IMDefinition.ps1')
  $(Join-Path -Path $functions -ChildPath 'Import-IMConfiguration.ps1')
  $(Join-Path -Path $functions -ChildPath 'Update-IMInstall.ps1')
  $(Join-Path -Path $functions -ChildPath 'New-IMDefinition.ps1')
  $(Join-Path -Path $functions -ChildPath 'Remove-IMDefinition.ps1')
  $(Join-Path -Path $functions -ChildPath 'Set-IMDefinition.ps1')
  # Finalize / Run any Module Functions defined above
  $(Join-Path -Path $Scripts -ChildPath 'RunFunctions.ps1')
)
foreach ($f in $ModuleFiles)
{
  . $f
}