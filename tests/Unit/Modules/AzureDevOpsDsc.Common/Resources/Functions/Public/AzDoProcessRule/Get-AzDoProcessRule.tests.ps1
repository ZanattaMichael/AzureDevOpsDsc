$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProcessRule" -Tag "Unit", "Process" {

    BeforeAll {

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProcessRule.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'ConvertTo-NormalizedRuleClause.ps1').FullName

        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Error
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Resolve-AzDoProcessWorkItemType -MockWith {
            return @{
                Process        = @{ id = 'proc-1' }
                WorkItemType   = @{ referenceName = 'Contoso.Incident' }
                IsCustomizable = $true
                Found          = $true
            }
        }

        $script:desiredConditions = @(@{ conditionType = 'when'; field = 'System.State'; value = 'Active' })
        $script:desiredActions    = @(@{ actionType = 'makeRequired'; targetField = 'Custom.Severity' })
    }

    Context "when the rule matches the desired state" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessRules -MockWith {
                return @(@{
                    id                = 'rule-1'
                    name              = 'Severity required'
                    customizationType = 'custom'
                    isDisabled        = $false
                    conditions        = @([PSCustomObject]@{ conditionType = 'when'; field = 'System.State'; value = 'Active' })
                    actions           = @([PSCustomObject]@{ actionType = 'makeRequired'; targetField = 'Custom.Severity'; value = $null })
                })
            }
        }

        It "returns status Unchanged" {
            $result = Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -RuleName 'Severity required' -Conditions $script:desiredConditions -Actions $script:desiredActions

            $result.status | Should -Be 'Unchanged'
        }

        It "does not report drift from the API filling in an omitted key" {
            # The action comes back with an explicit null 'value' the configuration never stated.
            $result = Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -RuleName 'Severity required' -Actions $script:desiredActions

            $result.propertiesChanged | Should -Not -Contain 'Actions'
        }

        It "carries the rule id for Set to address it by" {
            $result = Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required'
            $result.ruleId | Should -Be 'rule-1'
        }
    }

    Context "when the conditions differ" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessRules -MockWith {
                return @(@{
                    id         = 'rule-1'
                    name       = 'Severity required'
                    isDisabled = $false
                    conditions = @([PSCustomObject]@{ conditionType = 'when'; field = 'System.State'; value = 'Closed' })
                    actions    = @([PSCustomObject]@{ actionType = 'makeRequired'; targetField = 'Custom.Severity' })
                })
            }
        }

        It "reports Conditions as changed" {
            $result = Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -RuleName 'Severity required' -Conditions $script:desiredConditions

            $result.propertiesChanged | Should -Contain 'Conditions'
        }
    }

    Context "when the disabled flag differs" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessRules -MockWith {
                return @(@{ id = 'rule-1'; name = 'Severity required'; isDisabled = $false; conditions = @(); actions = @() })
            }
        }

        It "reports IsDisabled as changed" {
            $result = Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' `
                -RuleName 'Severity required' -IsDisabled $true

            $result.propertiesChanged | Should -Contain 'IsDisabled'
        }
    }

    Context "when the rule does not exist" {

        BeforeEach {
            Mock -CommandName List-DevOpsProcessRules -MockWith {
                return @(@{ id = 'rule-9'; name = 'Some other rule' })
            }
        }

        It "returns status NotFound" {
            $result = Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required'
            $result.status | Should -Be 'NotFound'
        }
    }
}
