<#
.SYNOPSIS
    DSC resource for managing Azure DevOps shared work item queries.

.DESCRIPTION
    Manages a saved query within a project's shared query tree, including its WIQL statement,
    display columns and sort order.

    The parent folder must already exist. Use AzDoQueryFolder with DependsOn to declare it.

.NOTES
    Author: Michael Zanatta

    Drift detection normalizes WIQL before comparing. The Queries API does not return the WIQL
    it was given - it re-indents, re-wraps and re-cases it - so a plain string comparison would
    report drift on every Test() forever. See ConvertTo-NormalizedWiql.

    Changes are applied in place with PATCH rather than by delete-and-recreate. Recreating a
    query changes its id, which silently breaks any dashboard widget, delivery plan or ACL
    token that references it.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER Path
    The full path of the query, including the root and any folders, for example
    'Shared Queries/Platform/Active Bugs'.

.PARAMETER Wiql
    The WIQL statement backing the query.

.PARAMETER QueryType
    'flat', 'tree' or 'oneHop'. Defaults to 'flat'.

.PARAMETER Columns
    Field reference names to display as columns, for example 'System.Id', 'System.Title'.

.PARAMETER SortColumns
    Sort order, as an array of hashtables: @{ Field = 'System.Id'; Descending = $false }.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoWorkItemQuery ActiveBugs
    {
        ProjectName = 'Contoso'
        Path        = 'Shared Queries/Platform/Active Bugs'
        Wiql        = "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
        Columns     = @('System.Id', 'System.Title', 'System.State')
        Ensure      = 'Present'
        DependsOn   = '[AzDoQueryFolder]Platform'
    }
#>

[DscResource()]
class AzDoWorkItemQuery : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [Alias('QueryPath')]
    [System.String]$Path

    [DscProperty()]
    [System.String]$Wiql

    [DscProperty()]
    [ValidateSet('flat', 'tree', 'oneHop')]
    [System.String]$QueryType = 'flat'

    [DscProperty()]
    [System.String[]]$Columns

    [DscProperty()]
    [HashTable[]]$SortColumns

    AzDoWorkItemQuery()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoWorkItemQuery] Get()
    {
        return [AzDoWorkItemQuery]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.Path         = $CurrentResourceObject.Path
        $properties.Wiql         = $CurrentResourceObject.Wiql
        $properties.QueryType    = $CurrentResourceObject.QueryType
        $properties.Columns      = $CurrentResourceObject.Columns
        $properties.SortColumns  = $CurrentResourceObject.SortColumns
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoWorkItemQuery] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
