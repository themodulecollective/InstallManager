###############################################################################################
# Module Removal
###############################################################################################
#Clean up objects that will exist in the Global Scope due to no fault of our own . . . like PSSessions
$OnRemoveScript = {
  # perform cleanup
  Write-Verbose -Verbose -Message 'module removal completing'
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript