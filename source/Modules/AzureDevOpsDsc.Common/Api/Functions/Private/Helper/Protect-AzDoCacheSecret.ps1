<#
.SYNOPSIS
Blanks the secret-bearing fields of cache entries, so no secret is held in a cache.

.DESCRIPTION
The Live* caches hold what the Azure DevOps API returned, and a read never returns a secret: a
secret variable comes back with a null value and a service connection's key comes back blank. A
write response is different - it can echo the request, secrets included - and New-/Set- functions
cache write responses. This function is the guarantee that such an echo is never held in a cache,
in memory or on disk, whatever a particular endpoint happens to return:

  - LiveVariableGroups:     the 'value' of every variable marked 'isSecret';
  - LiveServiceConnections: every 'authorization.parameters' entry whose name says it is a
                            secret (key, password, secret, token, certificate, credential);
  - LiveAuditStreams:       every such entry of 'consumerInputs'.

A blanked field is set to $null, which is exactly what a read of the same object returns, so
nothing that compares against the cache sees a difference. Entries are changed in place. Other
cache types are returned untouched.

It runs at every point a value enters a cache: Add-CacheItem (one entry, before it is stored),
Import-CacheObject (a file written by an earlier version may still hold a secret) and
Export-CacheObject (a last check before the file is written).

.PARAMETER CacheType
The cache the content belongs to.

.PARAMETER Content
The cache entry or entries (objects with a 'Value' property).

.PARAMETER PassThru
Return the number of values that were blanked.

.OUTPUTS
None, or System.Int32 with -PassThru. The entries are modified in place.
#>
function Protect-AzDoCacheSecret
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $CacheType,

        # Untyped, so binding does not enumerate or copy a whole cache. A single entry is accepted.
        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object]
        $Content,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    if (($CacheType -notin @('LiveVariableGroups', 'LiveServiceConnections', 'LiveAuditStreams')) -or ($null -eq $Content))
    {
        if ($PassThru.IsPresent) { return 0 }
        return
    }

    # A one-element array, so the nested helper can count without a script-scope variable.
    $blanked = @(0)

    $secretNamePattern = '(?i)key|password|passwd|pwd|secret|token|certificate|credential|sas'

    # A property bag is a hashtable when the module built it and a PSCustomObject when it came
    # from the API or from a cache file. These three helpers read and write either.
    function Get-BagName
    {
        param ($Bag)
        if ($Bag -is [System.Collections.IDictionary]) { return @($Bag.Keys) }
        if ($null -ne $Bag) { return @($Bag.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object { $_.Name }) }
        return @()
    }

    function Get-BagValue
    {
        param ($Bag, [System.String]$Name)
        if ($Bag -is [System.Collections.IDictionary]) { return $Bag[$Name] }
        return $Bag.PSObject.Properties[$Name].Value
    }

    function Clear-BagValue
    {
        param ($Bag, [System.String]$Name)
        if ($Bag -is [System.Collections.IDictionary])
        {
            if ($null -ne $Bag[$Name]) { $blanked[0]++ }
            $Bag[$Name] = $null
        }
        else
        {
            if ($null -ne $Bag.PSObject.Properties[$Name].Value) { $blanked[0]++ }
            $Bag.PSObject.Properties[$Name].Value = $null
        }
    }

    foreach ($entry in $Content)
    {
        if ($null -eq $entry) { continue }

        $value = $entry.Value
        if ($null -eq $value) { continue }

        switch ($CacheType)
        {
            'LiveVariableGroups'
            {
                $variables = Get-BagValue -Bag $value -Name 'variables'

                foreach ($variableName in (Get-BagName -Bag $variables))
                {
                    $variable = Get-BagValue -Bag $variables -Name $variableName

                    # A variable is either a plain value or a bag with 'value' and 'isSecret'.
                    if (($null -eq $variable) -or ($variable -is [System.String]) -or ($variable -is [System.ValueType])) { continue }

                    $names = Get-BagName -Bag $variable
                    if (($names -contains 'isSecret') -and ($names -contains 'value') -and [System.Boolean](Get-BagValue -Bag $variable -Name 'isSecret'))
                    {
                        Clear-BagValue -Bag $variable -Name 'value'
                    }
                }
            }

            'LiveServiceConnections'
            {
                $authorization = Get-BagValue -Bag $value -Name 'authorization'
                $parameters    = if ($null -ne $authorization) { Get-BagValue -Bag $authorization -Name 'parameters' }

                foreach ($parameterName in (Get-BagName -Bag $parameters))
                {
                    if ($parameterName -match $secretNamePattern) { Clear-BagValue -Bag $parameters -Name $parameterName }
                }
            }

            'LiveAuditStreams'
            {
                $consumerInputs = Get-BagValue -Bag $value -Name 'consumerInputs'

                foreach ($inputName in (Get-BagName -Bag $consumerInputs))
                {
                    if ($inputName -match $secretNamePattern) { Clear-BagValue -Bag $consumerInputs -Name $inputName }
                }
            }
        }
    }

    if ($PassThru.IsPresent) { return $blanked[0] }
}
