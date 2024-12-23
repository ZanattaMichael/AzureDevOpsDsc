<#
.SYNOPSIS
    Represents the API rate limit information.

.DESCRIPTION
    The APIRateLimit class encapsulates the details of API rate limiting, including retry-after duration,
    remaining rate limit, and rate limit reset time. It provides constructors to initialize these properties
    and a method to validate the input hashtable.

.PROPERTIES
    [Int]$retryAfter
        The duration (in seconds) to wait before retrying the API request.

    [Int]$xRateLimitRemaining
        The number of remaining API requests allowed in the current rate limit window.

    [Int]$xRateLimitReset
        The time (in Unix epoch format) when the rate limit will reset.

.METHODS
    [void] APIRateLimit([HashTable]$APIRateLimitObj)
        Constructor that initializes the APIRateLimit object using a hashtable containing the rate limit details.
        Throws an error if the hashtable is not valid.

    [void] APIRateLimit([int]$retryAfter)
        Constructor that initializes the APIRateLimit object with a specified retry-after duration.

    [Bool] isValid([HashTable]$APIRateLimitObj)
        Validates that the provided hashtable contains the expected keys for rate limit information.
        Returns $true if the hashtable is valid, otherwise returns $false.
#>

class APIRateLimit
{

    [Int]$retryAfter = 0
    [Int]$xRateLimitRemaining = 0
    [Int]$xRateLimitReset = 0

    # Constructor
    APIRateLimit([HashTable]$APIRateLimitObj)
    {

        # Validate that APIRateLimitObj is a HashTable and Contains the correct keys
        if (-not $this.isValid($APIRateLimitObj))
        {
            throw "The APIRateLimitObj is not valid."
        }

        # Convert X-RateLimit-Reset from Unix Time to DateTime
        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        # Set the properties of the class
        $this.retryAfter = [Int]($APIRateLimitObj.'Retry-After')
        $this.XRateLimitRemaining = [Int]$APIRateLimitObj.'X-RateLimit-Remaining'
        $this.XRateLimitReset = [Int]($APIRateLimitObj.'X-RateLimit-Reset')

    }

    # Constructor with retryAfter Parameters
    APIRateLimit($retryAfter)
    {

        # Set the properties of the class
        $this.retryAfter = [int]$retryAfter

    }

    Hidden [Bool]isValid($APIRateLimitObj)
    {

        # Assuming these are the keys we expect in the hashtable
        $expectedKeys = @('Retry-After', 'X-RateLimit-Remaining', 'X-RateLimit-Reset')

        # Check if all expected keys exist in the hashtable
        foreach ($key in $expectedKeys)
        {
            if (-not $APIRateLimitObj.ContainsKey($key))
            {
                Write-Warning "[APIRateLimit] The hashtable does not contain the expected key: $key"
                return $false
            }
        }

        # If all checks pass, return true
        Write-Verbose "[APIRateLimit] The hashtable is valid and contains all the expected keys."
        return $true

    }

}
