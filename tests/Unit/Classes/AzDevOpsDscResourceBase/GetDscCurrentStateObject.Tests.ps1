# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe "[AzDevOpsDscResourceBase]::GetDscCurrentStateObject() Tests" -Tag 'Unit', 'AzDevOpsDscResourceBase' {

    Context 'When no "DscCurrentStateResourceObject" object returned'{

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
        }

        It 'Should not throw' {
            $azDevOpsDscResourceBaseExample = [AzDevOpsDscResourceBaseExample]::new()

            {$azDevOpsDscResourceBaseExample.GetDscCurrentStateObject()} | Should -Not -Throw
        }

        It 'Should return an object with "Ensure" property value of "Absent"' {
            $azDevOpsDscResourceBaseExample = [AzDevOpsDscResourceBaseExample]::new()

            $azDevOpsDscResourceBaseExample.GetDscCurrentStateObject().Ensure | Should -Be 'Absent'
        }

    }


    Context 'When no "DscCurrentStateResourceObject" object returned'{

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
                return [PSObject]@{
                    Ensure = 'Present'
                }
            }
        }

        It 'Should not throw' {
            $azDevOpsDscResourceBaseExample = [AzDevOpsDscResourceBaseExample]::new()

            {$azDevOpsDscResourceBaseExample.GetDscCurrentStateObject()} | Should -Not -Throw
        }

        It 'Should return an object with "Ensure" property value of "Present"' {
            $azDevOpsDscResourceBaseExample = [AzDevOpsDscResourceBaseExample]::new()

            $azDevOpsDscResourceBaseExample.GetDscCurrentStateObject().Ensure | Should -Be 'Present'
        }

    }

}
