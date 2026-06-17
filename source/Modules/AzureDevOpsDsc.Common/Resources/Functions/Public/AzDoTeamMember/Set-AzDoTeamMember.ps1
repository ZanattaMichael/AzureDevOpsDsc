Function Set-AzDoTeamMember
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$MemberName,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    # Team membership is add/remove only — Set behaves the same as New
    Write-Verbose "[Set-AzDoTeamMember] Team membership has no update semantics. Delegating to New-AzDoTeamMember."
    New-AzDoTeamMember -ProjectName $ProjectName -TeamName $TeamName -MemberName $MemberName -Force:$Force
}
