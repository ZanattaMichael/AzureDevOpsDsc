Function Split-RecurivePath
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [int]$Times = 1
    )

    1 .. $Times | ForEach-Object {
        $Path = Split-Path -Path $Path -Parent
    }

    $Path
}

# Unload the $Global:RepositoryRoot and $Global:TestPaths variables
Remove-Variable -Name RepositoryRoot -Scope Global -ErrorAction SilentlyContinue

# Set the $Global:RepositoryRoot and $Global:TestPaths variables
$Global:RepositoryRoot = $PSScriptRoot

Import-Module -Name (Join-Path -Path $Global:RepositoryRoot -ChildPath '/tests/Unit/Modules/TestHelpers/CommonTestCases.psm1')
Import-Module -Name (Join-Path -Path $Global:RepositoryRoot -ChildPath '/tests/Unit/Modules/TestHelpers/CommonTestHelper.psm1')
Import-Module -Name (Join-Path -Path $Global:RepositoryRoot -ChildPath '/tests/Unit/Modules/TestHelpers/CommonTestFunctions.psm1')

$config = New-PesterConfiguration

$config.Run.Path                        = ".\tests\Unit\Modules\AzureDevOpsDsc.Common"
$config.Output.CIFormat                 = "GitHubActions"
$config.CodeCoverage.Enabled            = $true
$config.CodeCoverage.Path               = @(
                                            '.\source\Modules\AzureDevOpsDsc.Common\Api',
                                            '.\source\Modules\AzureDevOpsDsc.Common\Connection',
                                            '.\source\Modules\AzureDevOpsDsc.Common\en-US',
                                            '.\source\Modules\AzureDevOpsDsc.Common\LocalizedData',
                                            '.\source\Modules\AzureDevOpsDsc.Common\Resources',
                                            '.\source\Modules\AzureDevOpsDsc.Common\Services'
                                        )
$config.CodeCoverage.OutputFormat       = 'CoverageGutters'
$config.CodeCoverage.OutputPath         = ".\output\AzureDevOpsDsc.Common.codeCoverage.xml"
$config.CodeCoverage.OutputEncoding     = 'utf8'

# Get the path to the function being tested

Invoke-Pester -Configuration $config
