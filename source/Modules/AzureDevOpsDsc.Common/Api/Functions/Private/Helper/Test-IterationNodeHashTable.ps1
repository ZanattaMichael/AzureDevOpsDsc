function Test-IterationNodeHashTable {
    param(
        [Parameter(Mandatory = $true)]
        [HashTable[]]$IterationAttributes
    )

    # Validate the Iteration Attributes and Ensure that all the required properties are present (path, startdate, enddate (optional))
    ForEach ($Iteration in $IterationAttributes) {
        # Ensure that Iteration is a HashTable
        if (-not($Iteration -is [HashTable])) {
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
        if ($Iteration.ContainsKey('StartDate') -and (-not [DateTime]::TryParse($Iteration['StartDate'], [ref]$null))) {
            Write-Error '[Get-AzDoIterationNode] Invalid StartDate format. It must be a valid date.'
            return $false
        }

        if ($Iteration.ContainsKey('EndDate') -and (-not [DateTime]::TryParse($Iteration['EndDate'], [ref]$null))) {
            Write-Error '[Get-AzDoIterationNode] Invalid EndDate format. It must be a valid date.'
            return $false
        }

    }

    return $true

}
