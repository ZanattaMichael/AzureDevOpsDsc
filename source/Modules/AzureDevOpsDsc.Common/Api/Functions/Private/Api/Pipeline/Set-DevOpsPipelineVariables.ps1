<#
.SYNOPSIS
Creates or updates a set of pipeline (build definition) variables.

.DESCRIPTION
Pipeline variables live on the classic build definition, not on the Pipelines API resource, and a
'PUT' has to send the whole definition back. This reads the current definition, adds or replaces
each named variable in its 'variables' map, and writes the definition back - leaving every other
variable and every other field on the definition untouched.

Secret variable values are write-only: the API never returns one, so every call sends the value
the configuration currently holds. There is no way to detect, from here, whether that value
actually changed on the far end.

.PARAMETER ApiUri
The base organization API URI, e.g. 'https://dev.azure.com/myorg'.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER DefinitionId
The pipeline/build definition id.

.PARAMETER Variables
An array of hashtables shaped '@{ Name; Value; IsSecret; AllowOverride }'. 'IsSecret' and
'AllowOverride' default to $false when not present on an entry.

.EXAMPLE
Set-DevOpsPipelineVariables -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'MyProject' -DefinitionId 42 `
    -Variables @(@{ Name = 'Environment'; Value = 'Prod' }, @{ Name = 'ApiKey'; Value = 's3cr3t'; IsSecret = $true })
#>
Function Set-DevOpsPipelineVariables
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$DefinitionId,
        [Parameter(Mandatory)][Hashtable[]]$Variables
    )

    $definition = Get-DevOpsBuildDefinition -ApiUri $ApiUri -ProjectName $ProjectName -DefinitionId $DefinitionId

    if ($null -eq $definition)
    {
        Throw "[Set-DevOpsPipelineVariables] Could not read build definition '$DefinitionId' for '$ProjectName'."
    }

    $variablesNode = if ($null -ne $definition.variables) { $definition.variables } else { [PSCustomObject]@{} }

    foreach ($variable in $Variables)
    {
        $name = [string]$variable.Name
        $isSecret = if ($variable.ContainsKey('IsSecret')) { [bool]$variable.IsSecret } else { $false }
        $allowOverride = if ($variable.ContainsKey('AllowOverride')) { [bool]$variable.AllowOverride } else { $false }
        $value = if ($null -eq $variable.Value) { '' } else { [string]$variable.Value }

        $entry = [PSCustomObject]@{
            value         = $value
            isSecret      = $isSecret
            allowOverride = $allowOverride
        }

        if ($variablesNode.PSObject.Properties[$name])
        {
            $variablesNode.PSObject.Properties[$name].Value = $entry
        }
        else
        {
            $variablesNode | Add-Member -MemberType NoteProperty -Name $name -Value $entry -Force
        }
    }

    # A Hashtable accepts a dot-assignment to a key that does not exist yet; a PSCustomObject - the
    # shape a JSON-deserialized API response actually takes - throws unless the NoteProperty is
    # already present, which is only guaranteed when the API included a 'variables' field at all.
    if ($definition -is [System.Collections.IDictionary])
    {
        $definition.variables = $variablesNode
    }
    elseif ($definition.PSObject.Properties['variables'])
    {
        $definition.PSObject.Properties['variables'].Value = $variablesNode
    }
    else
    {
        $definition | Add-Member -MemberType NoteProperty -Name 'variables' -Value $variablesNode -Force
    }

    return Set-DevOpsBuildDefinition -ApiUri $ApiUri -ProjectName $ProjectName -DefinitionId $DefinitionId -Definition $definition
}
