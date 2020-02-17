[CmdletBinding()]
param(
    [parameter(Position=0)]
    $Task = 'Default'
)

$Script:Modules = @(

    'InvokeBuild',
    'Pester',
    #'platyPS',
    'PSScriptAnalyzer',
    'DependsOn'
)

$Script:ModuleInstallScope = 'CurrentUser'

'Starting build...'
'Installing module dependencies...'

Install-Module -Name $Script:Modules -Scope $Script:ModuleInstallScope -Force -SkipPublisherCheck

$Error.Clear()

"Invoking build action [$Task]"

Invoke-Build -Task $Task -Result 'Result'
if ($Result.Error)
{
    $Error[-1].ScriptStackTrace | Out-String
    exit 1
}

exit 0