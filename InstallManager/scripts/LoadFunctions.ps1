###############################################################################################
# Module Functions
###############################################################################################
$AllFunctionFiles = (Get-ChildItem -Recurse -File -Filter *.ps1 -Path $(Join-Path -Path $MyInvocation.PSScriptRoot -ChildPath 'Functions')).where( {
    $_.BaseName -in @(
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
  })

$AllFunctionFiles.foreach( { . $_.fullname })
