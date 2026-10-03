using module AzureDevOpsDscNative



Describe "[AzDevOpsDscResourceBase]::SetToDesiredState() Tests" -Tag "Unit", "AzDevOpsDscResourceBase" {

    class AzDevOpsDscResourceBaseExample : AzDevOpsDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
    {
        [string]$ApiUri = 'https://some.api/_apis/'
        [string]$Pat = '1234567890123456789012345678901234567890123456789012'

        [DscProperty(Key)]
        [string]$AzDevOpsDscResourceBaseExampleName = 'AzDevOpsDscResourceBaseExampleNameValue'

        [string]$AzDevOpsDscResourceBaseExampleId # = '31e71307-09b3-4d8a-b65c-5c714f64205f' # Random GUID

        [string]GetResourceName()
        {
            return 'AzDevOpsDscResourceBaseExample'
        }

        [Hashtable]GetDscCurrentStateObjectGetParameters()
        {
            return @{}
        }

        [PSObject]GetDscCurrentStateResourceObject([Hashtable]$GetParameters)
        {
            return $null
        }

        [string]GetResourceFunctionName([RequiredAction]$RequiredAction)
        {
            return 'Get-Module'
        }
        [Hashtable]GetDesiredStateParameters([Hashtable]$Current, [Hashtable]$Desired, [RequiredAction]$RequiredAction)
        {
            return @{
                Name = 'SomeModuleThatWillNotExist'
            }
        }

        [Int32]GetPostSetWaitTimeMs()
        {
            return 0
        }
    }

    # Uses the real GetDscRequiredAction(): Ensure = Absent against an 'Unchanged' lookup maps to Remove.
    class AzDevOpsDscResourceBaseCountingExample : AzDevOpsDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
    {
        [DscProperty(Key)]
        [string]$AzDevOpsDscResourceBaseExampleName = 'AzDevOpsDscResourceBaseExampleNameValue'

        [DscProperty()]
        [Ensure]$Ensure = [Ensure]::Absent

        [Int32]$CurrentStateReads = 0

        [string]GetResourceName()
        {
            return 'AzDevOpsDscResourceBaseCountingExample'
        }

        [Hashtable]GetDscCurrentStateProperties()
        {
            $this.CurrentStateReads++
            return @{
                Ensure       = [Ensure]::Present
                LookupResult = @{ Status = [DSCGetSummaryState]::Unchanged }
            }
        }

        [string]GetResourceFunctionName([RequiredAction]$RequiredAction)
        {
            return 'Invoke-SetToDesiredStateTestAction'
        }

        [Hashtable]GetDesiredStateParameters([Hashtable]$Current, [Hashtable]$Desired, [RequiredAction]$RequiredAction)
        {
            return @{
                RequiredAction = $RequiredAction
            }
        }
    }

    $testCasesValidRequiredActionThatDoNotRequireAction = @(
        @{
            RequiredAction = [RequiredAction]::Get
        },
        @{
            RequiredAction = [RequiredAction]::Test
        },
        @{
            RequiredAction = [RequiredAction]::Error
        }
    )

    $testCasesValidRequiredActionThatRequireAction = @(
        @{
            RequiredAction = [RequiredAction]::New
        },
        @{
            RequiredAction = [RequiredAction]::Set
        },
        @{
            RequiredAction = [RequiredAction]::Remove
        }
    )


    Context 'When no "GetDscRequiredAction()" method returns a "RequiredAction" that requires an action'{

        It 'Should not throw - "<RequiredAction>"' -TestCases $testCasesValidRequiredActionThatRequireAction {
            param ([RequiredAction]$RequiredAction)

            $azDevOpsDscResourceBase = [AzDevOpsDscResourceBaseExample]::new()
            [ScriptBlock]$getDscRequiredAction = {return $RequiredAction}
            $azDevOpsDscResourceBase | Add-Member -MemberType ScriptMethod -Name GetDscRequiredAction -Value $getDscRequiredAction -Force

            { $azDevOpsDscResourceBase.SetToDesiredState() } | Should -Not -Throw
        }

        It 'Should return $null - "<RequiredAction>"' -TestCases $testCasesValidRequiredActionThatDoNotRequireAction {
            param ([RequiredAction]$RequiredAction)

            $azDevOpsDscResourceBase = [AzDevOpsDscResourceBaseExample]::new()

            [ScriptBlock]$getDscRequiredAction = {return $RequiredAction}
            $azDevOpsDscResourceBase | Add-Member -MemberType ScriptMethod -Name GetDscRequiredAction -Value $getDscRequiredAction -Force

            $azDevOpsDscResourceBase.SetToDesiredState() | Should -BeNullOrEmpty
        }

    }


    Context 'When the resource is not in the desired state' {

        BeforeAll {
            function global:Invoke-SetToDesiredStateTestAction
            {
                param ($RequiredAction, $LookupResult)
                $global:SetToDesiredStateTestActionCalls += @(@{ RequiredAction = $RequiredAction; LookupResult = $LookupResult })
            }
        }

        BeforeEach {
            $global:SetToDesiredStateTestActionCalls = @()
        }

        AfterAll {
            Remove-Item -Path 'Function:\Invoke-SetToDesiredStateTestAction' -ErrorAction SilentlyContinue
            Remove-Variable -Name SetToDesiredStateTestActionCalls -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Should read the current state once and use it for both the action and its parameters' {

            $azDevOpsDscResourceBase = [AzDevOpsDscResourceBaseCountingExample]::new()

            $azDevOpsDscResourceBase.SetToDesiredState()

            $azDevOpsDscResourceBase.CurrentStateReads | Should -Be 1
            $global:SetToDesiredStateTestActionCalls.Count | Should -Be 1
            $global:SetToDesiredStateTestActionCalls[0].RequiredAction | Should -Be ([RequiredAction]::Remove)
            $global:SetToDesiredStateTestActionCalls[0].LookupResult.Status | Should -Be ([DSCGetSummaryState]::Unchanged)
        }

    }


    Context 'When no "GetDscRequiredAction()" method returns a "RequiredAction" that requires no action'{

        It 'Should not throw - "<RequiredAction>"' -TestCases $testCasesValidRequiredActionThatDoNotRequireAction {
            param ([RequiredAction]$RequiredAction)

            $azDevOpsDscResourceBase = [AzDevOpsDscResourceBaseExample]::new()
            [ScriptBlock]$getDscRequiredAction = {return $RequiredAction}
            $azDevOpsDscResourceBase | Add-Member -MemberType ScriptMethod -Name GetDscRequiredAction -Value $getDscRequiredAction -Force

            { $azDevOpsDscResourceBase.SetToDesiredState() } | Should -Not -Throw
        }

        It 'Should return $null - "<RequiredAction>"' -TestCases $testCasesValidRequiredActionThatDoNotRequireAction {
            param ([RequiredAction]$RequiredAction)

            $azDevOpsDscResourceBase = [AzDevOpsDscResourceBaseExample]::new()
            [ScriptBlock]$getDscRequiredAction = {return $RequiredAction}
            $azDevOpsDscResourceBase | Add-Member -MemberType ScriptMethod -Name GetDscRequiredAction -Value $getDscRequiredAction -Force

            $azDevOpsDscResourceBase.SetToDesiredState() | Should -BeNullOrEmpty
        }

    }

}

