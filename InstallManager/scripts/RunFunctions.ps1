###############################################################################################
# Import User's Configuration
###############################################################################################
Import-IMConfiguration
###############################################################################################
# Setup Tab Completion
###############################################################################################
# Tab Completions for IM Definition Names
$ImDefinitionsScriptBlock = {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
  $MyParams = @{ }
  if ($null -ne $fakeBoundParameter.InstallManager)
  {
    $MyParams.InstallManager = $fakeBoundParameter.InstallManager
  }
  if ($null -ne $wordToComplete)
  {
    $MyParams.Name = $wordToComplete + '*'
  }
  $MyNames = Get-IMDefinition @MyParams |
    Select-Object -expandProperty Name

  foreach ($n in $MyNames)
  {
    [System.Management.Automation.CompletionResult]::new($n, $n, 'ParameterValue', $n)
  }
}

Register-ArgumentCompleter -CommandName @(
  'Get-IMDefinition'
  'Set-IMDefinition'
  'Remove-IMDefinition'
  'Update-IMInstall'
) -ParameterName 'Name' -ScriptBlock $ImDefinitionsScriptBlock
