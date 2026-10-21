<#
    PSScriptAnalyzer settings for the script-analysis job in .github/workflows/unit-tests.yml.

    Deliberately a short, security-only rule set. The job exists to catch credential-handling
    mistakes in the module source - a token taken as a plain [string] parameter, a hand-built
    Basic auth header from a username/password pair, Invoke-Expression over API-supplied text -
    not to enforce style, so the general-purpose rules are not included and this file does not
    replace a full `Invoke-ScriptAnalyzer` run during development.

    Two rules that usually sit alongside these are left out on purpose:

      - PSAvoidUsingConvertToSecureStringWithPlainText: the token classes (ManagedIdentityToken,
        ServicePrincipalToken, AzureCliToken, WorkloadIdentityFederationToken, ...) receive an
        OAuth access token as plain text in an HTTP response body and have no way to turn it
        into a [SecureString] other than `ConvertTo-SecureString -AsPlainText`. The rule would
        flag every one of those and nothing that could be fixed.

      - PSAvoidUsingEmptyCatchBlock: a code-quality rule, not a security one. An empty catch
        is a deliberate "this probe may fail" in several places, and the job is scoped to
        findings that have a security consequence.

    The job itself filters out the TypeNotFound and ParseError pseudo-rules, which are not
    governed by this file: the resource classes reference types that exist only once the
    module is built, so standalone analysis reports TypeNotFound for them regardless.
#>
@{
    IncludeRules = @(
        'PSAvoidUsingPlainTextForPassword'
        'PSUsePSCredentialType'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingUsernameAndPasswordParams'
        'PSAvoidUsingComputerNameHardcoded'
        'PSAvoidUsingBrokenHashAlgorithms'
        'PSAvoidUsingAllowUnencryptedAuthentication'
    )
}
