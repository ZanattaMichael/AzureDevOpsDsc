$currentFile = $MyInvocation.MyCommand.Path

Describe "Wait-DevOpsGitImportRequest" -Tag "Unit", "GitRepository", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Wait-DevOpsGitImportRequest.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Write-Error

        # Otherwise the 'queued'/'started' branches would really sleep.
        Mock -CommandName Start-Sleep

        $mockProject = [PSCustomObject]@{ name = 'TestProject'; id = '12345' }
        $mockRepo    = [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id' }

        $baseParams = @{
            ApiUri          = "https://dev.azure.com/org"
            Project         = $mockProject
            Repository      = $mockRepo
            ImportRequestId = 'import-1'
            WaitIntervalMs  = 250
            WaitTimeoutMs   = 5000
            ApiVersion      = '7.1'
        }
    }

    Context "When the import completes on the first poll" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ importRequestId = 'import-1'; status = 'completed' }
            }
        }

        It "Should detect completion and exit the loop without polling again" {
            $result = Wait-DevOpsGitImportRequest @baseParams

            $result.status | Should -Be 'completed'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 0
        }
    }

    Context "When the import is still queued before it completes" {
        BeforeAll {
            $script:pollCount = 0
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                $script:pollCount++
                if ($script:pollCount -lt 2) {
                    return @{ importRequestId = 'import-1'; status = 'queued' }
                }
                return @{ importRequestId = 'import-1'; status = 'completed' }
            }
        }

        It "Should keep polling until a terminal status is reached" {
            $result = Wait-DevOpsGitImportRequest @baseParams

            $result.status | Should -Be 'completed'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 2
            Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 0
        }
    }

    Context "When the import request fails" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{
                    importRequestId = 'import-1'
                    status           = 'failed'
                    detailedStatus   = @{ errorMessage = 'Source repository could not be reached.' }
                }
            }
        }

        It "Should surface the failure as an error rather than returning silently" {
            $result = Wait-DevOpsGitImportRequest @baseParams

            $result.status | Should -Be 'failed'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
        }
    }

    Context "When the import request is abandoned" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ importRequestId = 'import-1'; status = 'abandoned' }
            }
        }

        It "Should treat 'abandoned' as a terminal failure" {
            $result = Wait-DevOpsGitImportRequest @baseParams

            $result.status | Should -Be 'abandoned'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
        }
    }

    Context "When the import never reaches a terminal status before the timeout" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ importRequestId = 'import-1'; status = 'queued' }
            }

            # Force the very first timeout check to report 'exceeded' so the loop stops
            # deterministically after a single poll instead of depending on real
            # wall-clock time (Start-Sleep is mocked away, so real timing would let the
            # loop spin far past 'WaitTimeoutMs' before Get-Date ever caught up).
            Mock -CommandName Test-AzDevOpsApiTimeoutExceeded -MockWith { return $true }
        }

        It "Should stop polling and write a timeout error rather than leaving the repository silently empty" {
            $result = Wait-DevOpsGitImportRequest @baseParams

            $result.status | Should -Be 'queued'
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
        }
    }
}
