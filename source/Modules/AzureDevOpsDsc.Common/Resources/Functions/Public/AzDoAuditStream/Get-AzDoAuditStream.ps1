Function Get-AzDoAuditStream
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$StreamName,
        [Parameter(Mandatory = $true)][string]$ConsumerType,
        [Parameter(Mandatory = $true)][HashTable]$ConsumerInputs,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoAuditStream] Started."

    # A value in ConsumerInputs may be a secret reference instead of the secret; fetch those now.
    # See Resolve-AzDoSecretReference.
    $ConsumerInputs = Resolve-AzDoSecretReferenceTable -Table $ConsumerInputs
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $stream = Get-CacheItem -Key $StreamName -Type 'LiveAuditStreams'
    if ($stream) { $result.liveCache = $stream; $result.status = [DSCGetSummaryState]::Unchanged }
    else          { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
