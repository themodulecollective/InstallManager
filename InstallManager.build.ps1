Task InstallDependencies {
  if ((Get-Module -Name Pester).count -lt 1)
  {
    Install-Module -Name Pester -Scope CurrentUser -Force
  }
  if ((Get-Module -Name PSScriptAnalyzer).count -lt 1)
  {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
  }
  if ((Get-Module -Name ASTHelper).count -lt 1)
  {
    Install-Module -Name ASTHelper -Scope CurrentUser -Force
  }
}

Task Tests {

  Import-Module Pester

  $invokePesterParams = @{
      Strict = $true
      PassThru = $true
      Verbose = $false
      EnableExit = $false
  }

  # Publish Test Results as NUnitXml
  $testResults = Invoke-Pester @invokePesterParams;

  $numberFails = $testResults.FailedCount
  assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

}

task CleanArtifacts {
  $Artifacts = $(Join-Path -Path $BuildRoot -ChildPath 'artifacts')

  if (Test-Path -Path $Artifacts)
  {
      Remove-Item $Artifacts -Recurse -Force
  }

  New-Item -ItemType Directory -Path $Artifacts -Force
}

Task BuildPSM1 {

  $ModuleManifest = $(Join-Path -Path $BuildRoot -ChildPath $(Split-Path -Path $BuildRoot -Leaf))
  $Module = Import-Module -FullyQualifiedName $ModuleManifest -PassThru
  Import-Module ASTHelper
  $PSM1SourceFiles = $Module.Invoke({Get-Variable -ValueOnly -Name ModuleFiles})
  Write-Information -MessageData  $PSM1SourceFiles -InformationAction Continue

}