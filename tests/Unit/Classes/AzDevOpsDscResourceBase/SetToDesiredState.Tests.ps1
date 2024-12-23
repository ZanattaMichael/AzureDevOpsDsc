

Describe "[AzDevOpsDscResourceBase]::SetToDesiredState() Tests" -Tag 'Unit', 'AzDevOpsDscResourceBase' {

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

