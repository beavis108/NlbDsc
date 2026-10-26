<#
    .SYNOPSIS
        Converts a value returned by the NLB cmdlets to the casing used in the
        ValueMap of a DSC resource schema.

    .DESCRIPTION
        The NLB cmdlets return enumeration values in different casing, for
        example 'UNICAST' or 'Tcp'. This function returns the matching entry of
        AllowedValues (compared case-insensitively) so the value returned by
        Get-TargetResource matches the schema. If no entry matches, the value
        is returned unchanged as a string.

    .PARAMETER Value
        The value to convert.

    .PARAMETER AllowedValues
        The values defined in the ValueMap of the schema.

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-NlbDscValue -Value 'IGMPMULTICAST' -AllowedValues 'Unicast', 'Multicast', 'IgmpMulticast'

        Returns 'IgmpMulticast'.
#>
function ConvertTo-NlbDscValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.Object]
        $Value,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AllowedValues
    )

    if ($null -eq $Value)
    {
        return $null
    }

    $stringValue = ([System.String] $Value).Trim()

    foreach ($allowedValue in $AllowedValues)
    {
        if ($allowedValue -eq $stringValue)
        {
            return $allowedValue
        }
    }

    return $stringValue
}
