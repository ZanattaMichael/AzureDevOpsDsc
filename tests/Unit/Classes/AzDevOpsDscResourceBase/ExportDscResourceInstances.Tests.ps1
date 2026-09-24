# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}
using module AzureDevOpsDscNative


Describe "[AzDevOpsDscResourceBase]::ExportDscResourceInstances() Tests" -Tag "Unit", "AzDevOpsDscResourceBase", "Export" {

    Context 'When the resource has an Export-<ResourceName> function' {

        class ExportDscResourceInstancesExampleA : AzDevOpsDscResourceBase
        {
            [DscProperty(Key)]
            [string]$Name

            [DscProperty()]
            [string]$Description

            [string]GetResourceName()
            {
                return 'ExportDscResourceInstancesExampleA'
            }
        }

        function Export-ExportDscResourceInstancesExampleA
        {
            return @(
                @{ Ensure = 'Present'; Name = 'One'; Description = 'First' },
                @{ Ensure = 'Present'; Name = 'Two'; Description = 'Second' }
            )
        }

        It 'Should not throw' {
            { [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleA]) } | Should -Not -Throw
        }

        It 'Should return one instance per hashtable Export-<ResourceName> returned' {
            $result = [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleA])
            $result.Count | Should -Be 2
        }

        It 'Should return instances of the requested type' {
            $result = [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleA])
            $result[0] | Should -BeOfType ([ExportDscResourceInstancesExampleA])
        }

        It 'Should copy every matching key onto the instance' {
            $result = [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleA])
            $one = $result | Where-Object { $_.Name -eq 'One' }

            $one.Description | Should -Be 'First'
            $one.Ensure | Should -Be 'Present'
        }

        It 'Should ignore a key on the returned hashtable that is not a property of the class' {
            function Export-ExportDscResourceInstancesExampleA
            {
                return @(
                    @{ Ensure = 'Present'; Name = 'One'; Description = 'First'; NotARealProperty = 'ignored' }
                )
            }

            { [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleA]) } | Should -Not -Throw
        }
    }

    Context 'When Export-<ResourceName> returns no results' {

        class ExportDscResourceInstancesExampleEmpty : AzDevOpsDscResourceBase
        {
            [DscProperty(Key)]
            [string]$Name

            [string]GetResourceName()
            {
                return 'ExportDscResourceInstancesExampleEmpty'
            }
        }

        function Export-ExportDscResourceInstancesExampleEmpty
        {
            return @()
        }

        It 'Should return an empty array without throwing' {
            $result = @([AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleEmpty]))
            $result.Count | Should -Be 0
        }
    }

    Context 'When the resource has no Export-<ResourceName> function' {

        class ExportDscResourceInstancesExampleNoExporter : AzDevOpsDscResourceBase
        {
            [DscProperty(Key)]
            [string]$Name

            [string]GetResourceName()
            {
                return 'ExportDscResourceInstancesExampleNoExporter'
            }
        }

        It 'Should throw an error naming the resource' {
            { [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleNoExporter]) } |
                Should -Throw -ExpectedMessage '*export is not implemented for ExportDscResourceInstancesExampleNoExporter*'
        }
    }

    Context 'When the resource declares a secret DscProperty' {

        class ExportDscResourceInstancesExampleSecret : AzDevOpsDscResourceBase
        {
            [DscProperty(Key)]
            [string]$Name

            [DscProperty()]
            [string]$ApiToken

            [string]GetResourceName()
            {
                return 'ExportDscResourceInstancesExampleSecret'
            }

            hidden [System.String[]]GetDscResourceSecretPropertyNames()
            {
                return @('ApiToken')
            }
        }

        function Export-ExportDscResourceInstancesExampleSecret
        {
            return @(
                @{ Ensure = 'Present'; Name = 'One'; ApiToken = 'the-real-secret-value' }
            )
        }

        It 'Should redact the secret property rather than returning its real value' {
            $result = [AzDevOpsDscResourceBase]::ExportDscResourceInstances([ExportDscResourceInstancesExampleSecret])
            $result[0].ApiToken | Should -Be '<REDACTED-BY-EXPORT>'
            $result[0].ApiToken | Should -Not -Be 'the-real-secret-value'
        }
    }
}
