$currentFile = $MyInvocation.MyCommand.Path

Describe "Resolve-AzDoProcessWorkItemType" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Resolve-AzDoProcessWorkItemType.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        Mock -CommandName Write-Verbose
    }

    Context "when the process is inherited and the work item type exists" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'proc-1'; name = 'Contoso Agile' } }
            Mock -CommandName Get-DevOpsProcess -MockWith {
                return @{ typeId = 'proc-1'; customizationType = 'inherited'; parentProcessTypeId = 'agile-id' }
            }
            Mock -CommandName List-DevOpsProcessWorkItemTypes -MockWith {
                return @(
                    @{ name = 'Bug'; referenceName = 'Contoso.Bug'; customization = 'system' },
                    @{ name = 'Incident'; referenceName = 'Contoso.Incident'; customization = 'custom' }
                )
            }
        }

        It "resolves the process and the work item type" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident'
            $result.Found | Should -BeTrue
            $result.WorkItemType.referenceName | Should -Be 'Contoso.Incident'
        }

        It "matches a work item type by reference name as well as display name" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Contoso Agile' -WorkItemTypeName 'Contoso.Incident'
            $result.Found | Should -BeTrue
        }

        It "reports the process as customizable" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident'
            $result.IsCustomizable | Should -BeTrue
        }

        It "resolves the process alone when no work item type is requested" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Contoso Agile' -WorkItemTypeName ''
            $result.Found | Should -BeTrue
            $result.WorkItemType | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName List-DevOpsProcessWorkItemTypes -Exactly -Times 0
        }
    }

    Context "when the process is a system process" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'agile-id'; name = 'Agile' } }
            Mock -CommandName Get-DevOpsProcess -MockWith {
                return @{ typeId = 'agile-id'; customizationType = 'system'; parentProcessTypeId = $null }
            }
            Mock -CommandName List-DevOpsProcessWorkItemTypes -MockWith { return @() }
        }

        It "reports it as not customizable" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Agile' -WorkItemTypeName 'Bug'
            $result.IsCustomizable | Should -BeFalse
            $result.Reason | Should -Be 'ProcessNotCustomizable'
        }

        It "does not go on to look up work item types" {
            Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Agile' -WorkItemTypeName 'Bug'
            Assert-MockCalled -CommandName List-DevOpsProcessWorkItemTypes -Exactly -Times 0
        }

        It "treats a process with no parent as a system process" {
            Mock -CommandName Get-DevOpsProcess -MockWith {
                return @{ typeId = 'agile-id'; parentProcessTypeId = '00000000-0000-0000-0000-000000000000' }
            }

            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Agile' -WorkItemTypeName 'Bug'
            $result.Reason | Should -Be 'ProcessNotCustomizable'
        }
    }

    Context "when the process does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return $null }
            Mock -CommandName Get-DevOpsProcess -MockWith { return $null }
            Mock -CommandName List-DevOpsProcessWorkItemTypes -MockWith { return @() }
        }

        It "reports ProcessNotFound" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Missing' -WorkItemTypeName 'Bug'
            $result.Reason | Should -Be 'ProcessNotFound'
            $result.Found | Should -BeFalse
        }
    }

    Context "when the work item type does not exist" {

        BeforeEach {
            Mock -CommandName Resolve-DevOpsProcess -MockWith { return @{ id = 'proc-1' } }
            Mock -CommandName Get-DevOpsProcess -MockWith {
                return @{ customizationType = 'inherited'; parentProcessTypeId = 'agile-id' }
            }
            Mock -CommandName List-DevOpsProcessWorkItemTypes -MockWith {
                return @(@{ name = 'Bug'; referenceName = 'Contoso.Bug' })
            }
        }

        It "reports WorkItemTypeNotFound" {
            $result = Resolve-AzDoProcessWorkItemType -Organization 'TestOrg' -ProcessName 'Contoso Agile' -WorkItemTypeName 'Missing'
            $result.Reason | Should -Be 'WorkItemTypeNotFound'
            $result.Found | Should -BeFalse
        }
    }
}
