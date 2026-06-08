Function Get-AzDoOrganizationName
{
    $orgName = $Global:DSCAZDO_OrganizationName

    if (-not [String]::IsNullOrEmpty($orgName))
    {
        return $orgName
    }

    # Fallback: read from cache file (handles isolated DSC runspace contexts)
    if ($ENV:AZDODSC_CACHE_DIRECTORY)
    {
        $settingsPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'ModuleSettings.clixml'
        if (Test-Path -LiteralPath $settingsPath)
        {
            $orgName = (Import-Clixml -LiteralPath $settingsPath).OrganizationName
        }
    }

    return $orgName
}
