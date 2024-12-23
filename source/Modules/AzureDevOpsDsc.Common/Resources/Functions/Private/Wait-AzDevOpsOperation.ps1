<#
    .SYNOPSIS
        Waits for an Azure DevOps API operation.

        NOTE: Use of one of the '-IsSuccessful' or '-IsComplete' switch is required.

    .PARAMETER ApiUri
        The URI of the Azure DevOps API to be connected to. For example:

          https://dev.azure.com/someOrganizationName/_apis/

    .PARAMETER Pat
        The 'Personal Access Token' (PAT) to be used by any subsequent requests/operations
        against the Azure DevOps API. This PAT must have the relevant permissions assigned
        for the subsequent operations being performed.

    .PARAMETER OperationId
        The 'id' of the Azure DevOps API operation. This is typically obtained from a response
        provided by the API when a request is made to it.

    .PARAMETER IsComplete
        Use of this switch will ensure the function waits for the Azure DevOps API operation
        to complete (Note: The operation could complete with error or/and without success).

        Failure to use this switch or the '-IsSuccessful' one as an alternative will throw an
        exception. An exception will also be thrown if the wait exceeds the timeout.

    .PARAMETER IsSuccessful
        Use of this switch will ensure the function waits for the Azure DevOps API operation
        to successfully complete (Note: The operation must complete with success).

        Failure to use this switch or the '-IsComplete' one as an alternative will throw an
        exception. An exception will also be thrown if the wait exceeds the timeout.

    .EXAMPLE
        Wait-AzDevOpsOperation -ApiUri 'YourApiUriHere' -Pat 'YourPatHere' -OperationId 'YourOperationId' `
                               -IsComplete

        Waits for the Azure DevOps 'Operation' (identified by the 'OperationId') to complete (although the
        operation may not complete successfully).

    .EXAMPLE
        Wait-AzDevOpsOperation -ApiUri 'YourApiUriHere' -Pat 'YourPatHere' -OperationId 'YourOperationId' `
                               -IsSuccessful

        Waits for the Azure DevOps 'Operation' (identified by the 'OperationId') to complete successfully.
#>
function Wait-AzDevOpsOperation
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-AzDevOpsApiUri -ApiUri $_ -IsValid })]
        [Alias('Uri')]
        [System.String]
        $ApiUri,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-AzDevOpsPat -Pat $_ -IsValid })]
        [Alias('PersonalAccessToken')]
        [System.String]
        $Pat,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-AzDevOpsOperationId -OperationId $_ -IsValid })]
        [Alias('Id')]
        [System.String]
        $OperationId,

        [Parameter()]
        [ValidateRange(250,10000)]
        [Alias('Interval','IntervalMilliseconds')]
        [System.Int32]
        $WaitIntervalMilliseconds = $(Get-AzDevOpsApiWaitIntervalMs),

        [Parameter()]
        [ValidateRange(250,300000)]
        [Alias('Timeout','TimeoutMilliseconds')]
        [System.Int32]
        $WaitTimeoutMilliseconds = $(Get-AzDevOpsApiWaitTimeoutMs),

        [Parameter(Mandatory = $true, ParameterSetName='IsComplete')]
        [ValidateSet($true)]
        [System.Management.Automation.SwitchParameter]
        $IsComplete,

        [Parameter(Mandatory = $true, ParameterSetName='IsSuccessful')]
        [ValidateSet($true)]
        [System.Management.Automation.SwitchParameter]
        $IsSuccessful
    )

    [System.DateTime]$waitStartDateTime = $(Get-Date).ToUniversalTime()

    $testOperationParameters = @{
        ApiUri      = $ApiUri
        Pat         = $Pat
        OperationId = $OperationId
    }

    if ($IsComplete)
    {
        $testOperationParameters.IsComplete = $IsComplete
    }

    if ($IsSuccessful)
    {
        $testOperationParameters.IsSuccessful = $IsSuccessful
    }

    while (-not(Test-AzDevOpsOperation @testOperationParameters))
    {
        Start-Sleep -Milliseconds $WaitIntervalMilliseconds

        if (Test-AzDevOpsApiTimeoutExceeded -StartTime $waitStartDateTime -End $($(Get-Date).ToUniversalTime()) -TimeoutMs $WaitTimeoutMilliseconds )
        {
            $errorMessage = $script:localizedData.AzDevOpsOperationWaitTimeoutExceeded -f $MyInvocation.MyCommand, $OperationId, $WaitTimeoutMilliseconds
            New-InvalidOperationException -Message $errorMessage
        }
    }
}
