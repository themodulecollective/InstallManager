function Export-IMDefinition
{
  [CmdletBinding()]
  param (
    $name,
    $Path
  )

  begin
  {

  }

  process
  {
    Export-Configuration -InputObject $script:IMConfiguration -DefaultPath $Path -Name $name
  }

  end
  {

  }
}