<#
.SYNOPSIS
    Validates a collection of iteration attributes to ensure they meet required criteria.

.PARAMETER IterationAttributes
    An array of hash tables representing iteration attributes. Each hash table must contain a 'Path' key.
    Optional keys include 'StartDate' and 'EndDate'. No other keys are permitted.

.RETURNS
    [bool] $true if all iteration attributes are valid, otherwise $false.

.EXAMPLE
    $iterations = @(
        @{ Path = 'Iteration 1'; StartDate = '2023-01-01'; EndDate = '2023-01-31' },
        @{ Path = 'Iteration 2'; StartDate = '2023-02-01' }
    )
    $result = Test-IterationNodeHashTable -IterationAttributes $iterations
    if ($result) {
        Write-Output 'All iterations are valid.'
    } else {
        Write-Output 'One or more iterations are invalid.'
    }

.NOTES
    This function checks that each hash table in the IterationAttributes array contains a 'Path' key.
    It also ensures that any 'StartDate' and 'EndDate' keys contain valid date formats.
    If any hash table contains keys other than 'Path', 'StartDate', or 'EndDate', the function returns $false.
#>
function Test-IterationNodeHashTable {
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$IterationAttributes
    )

    # Validate the Iteration Attributes and Ensure that all the required properties are present (path, startdate, enddate (optional))
    ForEach ($rawIteration in $IterationAttributes) {
        # Normalize to a real Hashtable — DSC serialization produces Deserialized objects that fail -is [HashTable]
        if ($rawIteration -is [HashTable]) {
            $Iteration = $rawIteration
        } elseif ($rawIteration -is [System.Collections.IDictionary]) {
            $Iteration = @{}; $rawIteration.Keys | ForEach-Object { $Iteration[$_] = $rawIteration[$_] }
        } elseif ($rawIteration -is [PSCustomObject]) {
            $Iteration = @{}; $rawIteration.PSObject.Properties | ForEach-Object { $Iteration[$_.Name] = $_.Value }
        } else {
            Write-Error '[Get-AzDoIterationNode] The iteration must be a HashTable.'
            return $false
        }

        # The Path Key is mandatory. StartDate and EndDate is not mandatory
        # All other properties are not permitted.

        # Check for mandatory 'Path' key
        if (-not $Iteration.ContainsKey('Path')) {
            Write-Error '[Get-AzDoIterationNode] The iteration must contain a "Path" key.'
            return $false
        }

        # Validate keys
        $allowedKeys = @('Path', 'StartDate', 'EndDate')
        foreach ($key in $Iteration.Keys) {
            if (-not $allowedKeys -contains $key) {
                Write-Error "[Get-AzDoIterationNode] Invalid property '$key'. Only 'Path', 'StartDate', and 'EndDate' are allowed."
                return $false
            }
        }

        # Optionally validate date formats if needed
        if ($Iteration.ContainsKey('StartDate') -and (-not(Test-Date -DateTime $Iteration['StartDate'] -FormatString $DateTimeFormatString))) {
            Write-Error '[Get-AzDoIterationNode] Invalid StartDate format. It must be a valid date.'
            return $false
        }

        if ($Iteration.ContainsKey('EndDate') -and (-not(Test-Date -DateTime $Iteration['EndDate'] -FormatString $DateTimeFormatString))) {
            Write-Error '[Get-AzDoIterationNode] Invalid EndDate format. It must be a valid date.'
            return $false
        }

        # If defined: Both StartDate and EndDate are required.
        if ($Iteration.ContainsKey('StartDate') -xor $Iteration.ContainsKey('EndDate')) {
            Write-Error '[Get-AzDoIterationNode] Both StartDate and EndDate must be provided if one is specified.'
            return $false
        }

    }

    return $true

}
