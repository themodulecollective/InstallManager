Task InstallDependencies {
  Install-Module -Name Pester -Scope CurrentUser -Force
  Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
}

Task Tests {
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

Task BuildPSM1 {
  
}