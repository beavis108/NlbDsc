<#
    .SYNOPSIS
        Converts the IP address of a port rule to the value expected by the
        parameter -IP of the NLB cmdlets.

    .DESCRIPTION
        The NLB cmdlets that address a port rule by IP address and port (for
        example Enable-NlbClusterPortRule -ClusterWide) expect the address
        255.255.255.255 for a port rule that applies to all cluster IP
        addresses. This function returns that address for 'All' and the IP
        address unchanged otherwise.

    .PARAMETER IPAddress
        The IP address of the port rule, or 'All'.

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-NlbCmdletIPAddress -IPAddress 'All'

        Returns '255.255.255.255'.
#>
function ConvertTo-NlbCmdletIPAddress
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $IPAddress
    )

    $normalizedIPAddress = ConvertTo-NlbPortRuleIPAddress -IPAddress $IPAddress

    if ($normalizedIPAddress -eq 'All')
    {
        return '255.255.255.255'
    }

    return $normalizedIPAddress
}
