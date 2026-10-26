<#
    .SYNOPSIS
        Tests whether two IP addresses are equal.

    .DESCRIPTION
        Compares two IPv4 or IPv6 addresses by value, so different notations
        of the same IPv6 address (for example with or without leading zeros)
        are treated as equal. Values that are not valid IP addresses are
        compared as strings (case-insensitive).

    .PARAMETER ReferenceIPAddress
        The first IP address.

    .PARAMETER DifferenceIPAddress
        The second IP address.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-NlbIPAddressEqual -ReferenceIPAddress 'fe80::0a' -DifferenceIPAddress 'FE80::A'

        Returns $true.
#>
function Test-NlbIPAddressEqual
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $ReferenceIPAddress,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $DifferenceIPAddress
    )

    $referenceValue = $null
    $differenceValue = $null

    if ([System.Net.IPAddress]::TryParse([System.String] $ReferenceIPAddress, [ref] $referenceValue) -and
        [System.Net.IPAddress]::TryParse([System.String] $DifferenceIPAddress, [ref] $differenceValue))
    {
        return $referenceValue.Equals($differenceValue)
    }

    return [System.String] $ReferenceIPAddress -eq [System.String] $DifferenceIPAddress
}
