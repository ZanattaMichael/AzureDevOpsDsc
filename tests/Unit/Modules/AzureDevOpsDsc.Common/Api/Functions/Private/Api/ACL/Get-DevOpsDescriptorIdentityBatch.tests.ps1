$currentFile = $MyInvocation.MyCommand.Path

Describe 'Get-DevOpsDescriptorIdentityBatch' -Tag "Unit", "ACL", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-DevOpsDescriptorIdentityBatch.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        $OrganizationName = 'MyOrg'

        Mock -CommandName Get-AzDevOpsApiVersion { return '7.1' }

        # Answers any batch with one identity per requested descriptor, so a test can count
        # requests without having to spell out a response per case.
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            $requested = @(($ApiUri -replace '^.*subjectDescriptors=', '') -replace '&.*$', '' -split ',')

            @{
                count = $requested.Count
                value = @(
                    $requested | ForEach-Object {
                        [PSCustomObject]@{
                            id                  = "id-$_"
                            descriptor          = "acl-$_"
                            subjectDescriptor   = $_
                            providerDisplayName = "display-$_"
                            isActive            = $true
                            isContainer         = $false
                        }
                    }
                )
            }
        }
    }

    Context 'Batching' {

        It 'Resolves every descriptor in a single request when they fit' {
            $descriptors = 1..10 | ForEach-Object { "vssgp.descriptor$_" }

            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName -SubjectDescriptor $descriptors

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1 -Scope It
            $result.Count | Should -Be 10
            $result['vssgp.descriptor7'].id | Should -Be 'id-vssgp.descriptor7'
        }

        It 'Splits into several requests once MaxBatchSize is reached' {
            $descriptors = 1..10 | ForEach-Object { "vssgp.descriptor$_" }

            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor $descriptors -MaxBatchSize 4

            # 10 descriptors, 4 per request.
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 3 -Scope It
            $result.Count | Should -Be 10
        }

        It 'Splits on URI length rather than overflowing a single request' {
            $descriptors = 1..10 | ForEach-Object { "vssgp.$('x' * 100)$_" }

            $null = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor $descriptors -MaxUriLength 400

            # Every URI built has to stay inside the budget - that is the whole point of
            # packing by length, and a fixed batch count would not guarantee it.
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Scope It -ParameterFilter {
                $ApiUri.Length -le 400
            }
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 0 -Scope It -ParameterFilter {
                $ApiUri.Length -gt 400
            }
        }

        It 'Ignores empty and duplicate descriptors' {
            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor @('vssgp.a', '', 'vssgp.a', '   ', 'vssgp.b')

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1 -Scope It -ParameterFilter {
                $ApiUri -match 'subjectDescriptors=vssgp\.a,vssgp\.b&'
            }
            $result.Count | Should -Be 2
        }

        It 'Makes no API call for an empty descriptor set' {
            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName -SubjectDescriptor @()

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 0 -Scope It
            $result | Should -BeOfType [Hashtable]
            $result.Count | Should -Be 0
        }
    }

    Context 'Keying' {

        It 'Keys on the subject descriptor the API returned, not on request order' {
            # The endpoint does not promise to answer in the order it was asked, so pairing
            # request position to response position would mis-key every identity.
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                @{
                    count = 2
                    value = @(
                        [PSCustomObject]@{ id = 'id-b'; subjectDescriptor = 'vssgp.b' }
                        [PSCustomObject]@{ id = 'id-a'; subjectDescriptor = 'vssgp.a' }
                    )
                }
            }

            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor @('vssgp.a', 'vssgp.b')

            $result['vssgp.a'].id | Should -Be 'id-a'
            $result['vssgp.b'].id | Should -Be 'id-b'
        }

        It 'Omits a descriptor the API did not answer for' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                @{
                    count = 1
                    value = @([PSCustomObject]@{ id = 'id-a'; subjectDescriptor = 'vssgp.a' })
                }
            }

            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor @('vssgp.a', 'vssgp.missing')

            $result.ContainsKey('vssgp.a') | Should -BeTrue
            $result.ContainsKey('vssgp.missing') | Should -BeFalse
        }

        It 'Flattens a paged response' {
            # Invoke-AzDevOpsApiRestMethod returns one object per continuation-token page.
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                @(
                    @{ value = @([PSCustomObject]@{ id = 'id-a'; subjectDescriptor = 'vssgp.a' }) }
                    @{ value = @([PSCustomObject]@{ id = 'id-b'; subjectDescriptor = 'vssgp.b' }) }
                )
            }

            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor @('vssgp.a', 'vssgp.b')

            $result.Count | Should -Be 2
        }
    }

    Context 'Failure handling' {

        It 'Retries a failed batch one descriptor at a time' {
            # One bad descriptor must not cost the whole batch: this function runs inside a
            # cache refresh that a DSC operation is waiting on.
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                if ($ApiUri -match ',') { throw 'batch rejected' }

                if ($ApiUri -match 'vssgp\.bad') { throw 'no such identity' }

                $descriptor = ($ApiUri -replace '^.*subjectDescriptors=', '') -replace '&.*$', ''
                @{ value = @([PSCustomObject]@{ id = "id-$descriptor"; subjectDescriptor = $descriptor }) }
            }

            $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor @('vssgp.a', 'vssgp.bad', 'vssgp.b') -WarningAction SilentlyContinue

            $result.Count | Should -Be 2
            $result['vssgp.a'].id | Should -Be 'id-vssgp.a'
            $result['vssgp.b'].id | Should -Be 'id-vssgp.b'
        }

        It 'Does not throw when every descriptor fails' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw 'unavailable' }

            $result = $null
            { $result = Get-DevOpsDescriptorIdentityBatch -OrganizationName $OrganizationName `
                -SubjectDescriptor @('vssgp.a', 'vssgp.b') -WarningAction SilentlyContinue } | Should -Not -Throw

            $result.Count | Should -Be 0
        }
    }
}
