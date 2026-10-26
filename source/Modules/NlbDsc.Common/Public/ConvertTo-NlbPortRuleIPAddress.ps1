<#
    .SYNOPSIS
        Normalizes the IP address of an NLB port rule.

    .DESCRIPTION
        A port rule that applies to all cluster IP addresses can be represented
        as 'All', '0.0.0.0', '255.255.255.255' or an empty value depending on the
        source (user input, cmdlet output, WMI). This function returns 'All' for
        all of these representations and the trimmed IP address otherwise, so
        values can be compared reliably.

    .PARAMETER IPAddress
        The IP address to normalize.

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-NlbPortRuleIPAddress -IPAddress '255.255.255.255'

        Returns 'All'.
#>
function ConvertTo-NlbPortRuleIPAddress
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.Object]
        $IPAddress
    )

    $value = ([System.String] $IPAddress).Trim()

    if ([System.String]::IsNullOrEmpty($value) -or $value -in @('All', '0.0.0.0', '255.255.255.255'))
    {
        return 'All'
    }

    return $value
}
