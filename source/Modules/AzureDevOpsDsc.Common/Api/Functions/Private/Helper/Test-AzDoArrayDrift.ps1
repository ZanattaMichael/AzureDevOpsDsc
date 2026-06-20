Function Test-AzDoArrayDrift
{
    <#
        .SYNOPSIS
            Returns $true when two string collections differ, tolerating null/empty inputs.
        .DESCRIPTION
            Compare-Object throws when a reference or difference collection is empty, because an
            empty array unrolls to $null when bound to its (mandatory) parameters. This helper
            normalises both sides to arrays, short-circuits on a count mismatch, and only calls
            Compare-Object when both sides are non-empty — making array drift detection safe for
            DSC resources where unmanaged properties arrive as $null.
        .OUTPUTS
            System.Boolean. $true if the collections differ; otherwise $false.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter()][AllowNull()][object[]]$Reference,
        [Parameter()][AllowNull()][object[]]$Difference
    )

    $ref  = @($Reference  | Where-Object { $null -ne $_ })
    $diff = @($Difference | Where-Object { $null -ne $_ })

    if ($ref.Count -ne $diff.Count) { return $true }
    if ($diff.Count -eq 0)          { return $false }

    return [bool](Compare-Object -ReferenceObject $ref -DifferenceObject $diff)
}
