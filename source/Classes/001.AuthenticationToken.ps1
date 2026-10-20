<#
    .SYNOPSIS
        Represents an authentication token with methods to manage and retrieve the token securely.

    .DESCRIPTION
        The AuthenticationToken class encapsulates an authentication token, providing methods to convert a SecureString to a String,
        test the call stack for specific functions, and ensure that the Get() method is called only by authorized functions.

    .PROPERTIES
        [TokenType]$tokenType
            The type of the token.

        hidden [bool]$linux
            Indicates if the environment is Linux.

        hidden [SecureString]$access_token
            The secure access token.

    .METHODS
        hidden [String] ConvertFromSecureString([SecureString]$SecureString)
            Converts a SecureString to a plain String.

        hidden [Bool] TestCallStack([String]$name)
            Tests the call stack to check if a specific function is in the call stack.

        TestCaller()
            Throws unless one of the module's own request-path functions is on the call stack.

        [String] Get()
            Retrieves the access token after TestCaller() has passed.

    .NOTES
        The call-stack check in TestCaller() is a guard against accidental use of the plain token
        outside the module's request path. It is not a security boundary: any code in the same
        process can define a function with an allowed name, or read the hidden SecureString
        directly. See the comment above TestCaller().
#>

class AuthenticationToken
{
    [TokenType] $tokenType
    hidden [bool] $linux = $isLinux
    hidden [SecureString] $access_token

    # Function to convert a SecureString to a String
    hidden [String] ConvertFromSecureString([SecureString] $SecureString)
    {
        # Convert a SecureString to a String
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $plainTextString = $(
            if ($this.linux)
            {
                [System.Runtime.InteropServices.Marshal]::PtrToStringUni($BSTR)
            } else {
                [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            }
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        )
        return $plainTextString

    }

    # Function to test the call stack
    hidden [Bool] TestCallStack([String] $name)
    {
        # Get the call stack
        Write-Verbose "[AuthenticationToken] Getting the call stack."
        $CallStack = Get-PSCallStack

        # Check if any of the callers in the call stack is Invoke-DSCResource
        foreach ($stackFrame in $CallStack)
        {
            if ($stackFrame.Command -eq $name)
            {
                Write-Verbose "[AuthenticationToken] The calling function is $name."
                return $true
            }
        }
        return $false
    }

    <#
        Guard against *accidental* use of the token outside the module's own request path.

        Get() is allowed only while one of these functions is on the call stack:
          - Add-AuthenticationHTTPHeader
          - Invoke-AzDevOpsApiRestMethod
          - New-AzDoAuthenticationProvider

        That catches the honest mistakes - a resource function, a test or an interactive session
        calling $Global:DSCAZDO_AuthenticationToken.Get() and dropping the plain token into a
        log, a verbose stream or a return value - and it keeps the places that handle the plain
        token to three.

        It is NOT a security boundary. Any code running in the same process can define a
        function with one of the allowed names and call Get() from inside it, can read the
        hidden access_token SecureString directly and decode it, or can call
        ConvertFromSecureString itself. Nothing here can stop that, and nothing in the module
        relies on it being stopped: the token's confidentiality rests on who can run code in
        this process and read the cache directory, not on this check.

        Earlier versions also "refused" Get() when Write-* or Out-File was on the stack. Those
        checks could never fire - TestCallStack compares whole command names, and an argument
        such as Write-Verbose ($token.Get()) is evaluated in the caller's frame before the
        cmdlet is ever invoked, so no Write-* frame exists while Get() runs - and they have been
        removed rather than left to suggest a protection that was never there.
    #>
    TestCaller()
    {
        if (
            (-not($this.TestCallStack('Add-AuthenticationHTTPHeader'))) -and
            (-not($this.TestCallStack('Invoke-AzDevOpsApiRestMethod'))) -and
            (-not($this.TestCallStack('New-AzDoAuthenticationProvider')))
        )
        {
            throw "[AuthenticationToken][Access Denied] The Get() method can only be called within AzureDevOpsDsc.Common."
        }
    }

    # Return the access token
    [String] Get()
    {
        # Verbose output
        Write-Verbose "[AuthenticationToken] Getting the access token:"
        Write-Verbose "[AuthenticationToken] Ensuring that the calling function is allowed to call the Get() method."

        # Test the caller
        $this.TestCaller()

        Write-Verbose "[AuthenticationToken] Token Retrieval Successful."

        # Return the access token
        return ($this.ConvertFromSecureString($this.access_token))
    }
}
