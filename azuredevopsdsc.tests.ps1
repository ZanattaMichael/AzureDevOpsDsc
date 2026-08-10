[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $LoadModulesOnly
)

# Unload the $Global:RepositoryRoot and $Global:TestPaths variables
Remove-Variable -Name RepositoryRoot -Scope Global -ErrorAction SilentlyContinue

# Set the $Global:RepositoryRoot and $Global:TestPaths variables
$Global:RepositoryRoot = $PSScriptRoot
$PublicDirectory = "$Global:RepositoryRoot\source\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public"
$Global:ClassesLoaded = $true

#
# Load the Helper Modules
Import-Module -Name (Join-Path -Path $Global:RepositoryRoot -ChildPath 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1')


#
# Load all the Helper Functions from the AzureDevOpsDsc.Common Module into Memory
Get-ChildItem -LiteralPath "$($Global:RepositoryRoot)\source\Modules\AzureDevOpsDsc.Common\Api\Functions\Private\Helper" -File -Recurse -Filter *.ps1 | ForEach-Object {
    Write-Verbose "Dot Sourcing $($_.FullName)"
    . $_.FullName
}

# Load all the Cache Functions from the AzureDevOpsDsc.Common Module into Memory
Get-ChildItem -LiteralPath "$($Global:RepositoryRoot)\source\Modules\AzureDevOpsDsc.Common\Api\Functions\Private\Cache" -File -Recurse -Filter *.ps1 | ForEach-Object {
    Write-Verbose "Dot Sourcing $($_.FullName)"
    . $_.FullName
}

# Load all the Public Functions from the AzureDevOpsDsc.Common Module into Memory
Get-ChildItem -LiteralPath $PublicDirectory -File -Recurse -Filter *.ps1 | ForEach-Object {
    Write-Verbose "Dot Sourcing $($_.FullName)"
    . $_.FullName
}


if ($LoadModulesOnly.IsPresent)
{
    return
}

$config = New-PesterConfiguration

$config.Run.Path                        = ".\tests\Unit\Classes"
$config.Output.CIFormat                 = "GitHubActions"
#$config.Output.Verbosity                = "Detailed"
$config.CodeCoverage.Enabled            = $true
$config.CodeCoverage.Path               = @(
                                            '.\source\Classes\'
                                        )
$config.CodeCoverage.OutputFormat       = 'CoverageGutters'
$config.CodeCoverage.OutputPath         = ".\output\AzureDevOpsDsc.codeCoverage.xml"
$config.CodeCoverage.OutputEncoding     = 'utf8'

# Get the path to the function being tested

Invoke-Pester -Configuration $config






