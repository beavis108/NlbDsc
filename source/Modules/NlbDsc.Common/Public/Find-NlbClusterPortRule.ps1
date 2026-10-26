<#
    .SYNOPSIS
        Returns the port rule that matches the IP address and contains the
        start port, or $null.

    .DESCRIPTION
        Enumerates the port rules of a cluster (cluster-wide settings) or of a
        cluster node (node specific settings such as load weight and handling
        priority) and returns the rule for IPAddress whose port range contains
        StartPort. A rule that starts exactly at StartPort is preferred.

    .PARAMETER InputObject
        A cluster object (Get-NlbDscCluster) or a node object (Find-NlbClusterNode).

    .PARAMETER IPAddress
        The cluster IP address of the port rule ('All' for all addresses).

    .PARAMETER StartPort
        The port that must be part of the port range of the rule.

    .OUTPUTS
        Microsoft.NetworkLoadBalancingClusters.PowerShell.PortRule

    .EXAMPLE
        Find-NlbClusterPortRule -InputObject $cluster -IPAddress 'All' -StartPort 80
#>
function Find-NlbClusterPortRule
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.UInt16]
        $StartPort
    )

    $normalizedIPAddress = ConvertTo-NlbPortRuleIPAddress -IPAddress $IPAddress

    $portRules = @(
        $InputObject | Get-NlbClusterPortRule -ErrorAction 'Stop' | Where-Object -FilterScript {
            $ruleIPAddress = Get-NlbObjectPropertyValue -InputObject $_ -Name 'VirtualIPAddress', 'IPAddress', 'IP'
            $ruleStartPort = Get-NlbObjectPropertyValue -InputObject $_ -Name 'StartPort', 'Start'
            $ruleEndPort = Get-NlbObjectPropertyValue -InputObject $_ -Name 'EndPort', 'End'

            (ConvertTo-NlbPortRuleIPAddress -IPAddress $ruleIPAddress) -eq $normalizedIPAddress -and
            [System.UInt32] $ruleStartPort -le $StartPort -and
            [System.UInt32] $ruleEndPort -ge $StartPort
        }
    )

    $exactMatch = $portRules | Where-Object -FilterScript {
        [System.UInt32] (Get-NlbObjectPropertyValue -InputObject $_ -Name 'StartPort', 'Start') -eq $StartPort
    } | Select-Object -First 1

    if ($exactMatch)
    {
        return $exactMatch
    }

    return $portRules | Select-Object -First 1
}
