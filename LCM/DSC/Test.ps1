using module "C:\Temp\AzureDevOpsDSC\output\AzureDevOpsDsc\0.0.0\AzureDevOpsDsc.psd1"

$ErrorActionPreference = "break"
Write-Host -Message ([xAzDoOrganizationGroup]::new | out-string)
$a = [xAzDoOrganizationGroup]::new()
