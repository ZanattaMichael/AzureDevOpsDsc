<#
    .SYNOPSIS
        Defines a base class from which other DSC resources inherit from.
#>
class DscResourceBase
{
    # Which properties of a resource class are DSC properties, and which one is its key, is fixed
    # by the class definition. Both are read through reflection, and Get(), Test() and Set() each
    # ask several times, so the answers are kept per type for the life of the session.
    hidden static [System.Collections.Hashtable] $DscResourceKeyPropertyNameCache = [System.Collections.Hashtable]::Synchronized(@{})
    hidden static [System.Collections.Hashtable] $DscResourcePropertyNamesCache = [System.Collections.Hashtable]::Synchronized(@{})

    hidden [System.String]GetDscResourceKey()
    {
        [System.String]$dscResourceKeyPropertyName = $this.GetDscResourceKeyPropertyName()

        if ([String]::IsNullOrWhiteSpace($dscResourceKeyPropertyName))
        {
            $errorMessage = "Cannot obtain a 'DscResourceKey' value for the '$($this.GetType().Name)' instance."
            throw (New-InvalidOperationException -Message $errorMessage)
        }

        return $this."$dscResourceKeyPropertyName"
    }

    hidden [System.String]GetDscResourceKeyPropertyName()
    {
        [System.String[]]$dscResourceKeyPropertyNames = @()

        [Type]$thisType = $this.GetType()

        $cachedKeyPropertyName = [DscResourceBase]::DscResourceKeyPropertyNameCache[$thisType]
        if ($null -ne $cachedKeyPropertyName)
        {
            return $cachedKeyPropertyName
        }

        [System.Reflection.PropertyInfo[]]$thisProperties = $thisType.GetProperties()

        $thisProperties | ForEach-Object {

            [System.Reflection.PropertyInfo]$propertyInfo = $_
            $PropertyName = $_.Name

            $propertyInfo.GetCustomAttributes($true) | ForEach-Object {

                if ($_.TypeId.Name -eq 'DscPropertyAttribute' -and
                    $_.Key -eq $true)
                {
                    $dscResourceKeyPropertyNames += $PropertyName
                }
            }
        }

        if ($null -eq $dscResourceKeyPropertyNames -or $dscResourceKeyPropertyNames.Count -eq 0)
        {
            $errorMessage = "Could not obtain a 'DscResourceDscKey' property for type '$($this.GetType().Name)'."
            throw (New-InvalidOperationException -Message $errorMessage)

        }
        elseif ($dscResourceKeyPropertyNames.Count -gt 1)
        {
            $errorMessage = "Obtained more than 1 property for type '$($this.GetType().Name)' that was marked as a 'Key'. There must only be 1 property on the class set as the 'Key' for DSC."
            throw (New-InvalidOperationException -Message $errorMessage)
        }

        # Only a valid answer is kept: a class with no key, or more than one, throws every time.
        [DscResourceBase]::DscResourceKeyPropertyNameCache[$thisType] = $dscResourceKeyPropertyNames[0]

        return $dscResourceKeyPropertyNames[0]
    }


    hidden [System.String[]]GetDscResourcePropertyNames()
    {
        [System.String[]]$thisDscPropertyNames = @()

        [Type]$thisType = $this.GetType()

        $cachedPropertyNames = [DscResourceBase]::DscResourcePropertyNamesCache[$thisType]
        if ($null -ne $cachedPropertyNames)
        {
            # A copy, so that a caller changing the array cannot change the cached one.
            return [System.String[]]$cachedPropertyNames.Clone()
        }

        [System.Reflection.PropertyInfo[]]$thisProperties = $thisType.GetProperties()

        $thisProperties | ForEach-Object {
            $propertyInfo = $_
            $PropertyName = $_.Name

            $propertyInfo.GetCustomAttributes($true) | ForEach-Object {

                if ($_.TypeId.Name -eq 'DscPropertyAttribute' -and -not $_.NotConfigurable)
                {
                    $thisDscPropertyNames += $PropertyName
                }
            }
        }

        [DscResourceBase]::DscResourcePropertyNamesCache[$thisType] = [System.String[]]$thisDscPropertyNames.Clone()

        return $thisDscPropertyNames
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

}
